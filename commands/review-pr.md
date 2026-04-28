---
description: Review PR checks and address code review feedback using gh CLI
agent: build
---

# PR Review and Feedback Handler

Input: PR_NUMBER (e.g., "128" or full URL like "https://github.com/owner/repo/pull/128")

## Step 1: Identify PR and Check Status

First, confirm the PR exists and get its current state:

```bash
gh pr view "$PR_NUMBER" --json number,state,title,url,headRefName,baseRefName
gh pr checks "$PR_NUMBER"
```

If the PR is already MERGED or CLOSED, stop and inform the user.

If CI checks are failing:
1. Identify failing jobs from the output
2. Get run ID from the check output
3. Run `gh run view <RUN_ID> --log-failed` to see failure details
4. Attempt to fix the failures
5. Commit fixes with: `git commit -m "ci: fix failing checks [PR #${PR_NUMBER}]"`

## Step 2: Fetch Review Threads

Use GraphQL to get all unresolved review threads:

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          comments(first: 10) {
            nodes {
              id
              author { login }
              body
              createdAt
              outdated
            }
          }
        }
      }
    }
  }
}' -f owner="$OWNER" -f repo="$REPO" -f pr="$PR_NUMBER"
```

Filter for threads where `isResolved: false`. Skip threads where `isOutdated: true` (stale comments).

## Step 3: Process Each Unresolved Thread

For each unresolved thread, categorize and act:

### Category A: Requires Code Fix

1. Read the referenced file at the specific line
2. Make the necessary code change
3. Stage the file: `git add <file>`
4. Create a dedicated commit: `git commit -m "fix: <description> [Addresses PR comment on <file>:<line>]"`

### Category B: False Positive / Won't Fix

Prepare an explanation for why no change is needed.

### Category C: Needs Clarification

Prepare a question to ask the reviewer.

**Important**: Do NOT reply to threads yet - wait until all fixes are committed AND pushed.

## Step 4: Push All Changes

After all fixes are committed:

```bash
git push
```

Verify the push succeeded with `git status` showing "up to date with origin".

## Step 5: Reply to and Resolve Threads

ONLY after pushing, reply to each addressed thread:

```bash
# For fixed issues
gh api graphql -f query='
mutation($threadId: ID!, $body: String!) {
  addPullRequestReviewThreadReply(input: {
    pullRequestReviewThreadId: $threadId
    body: $body
  }) {
    comment { id }
  }
}' -f threadId="$THREAD_ID" -f body="Fixed in commit $COMMIT_SHA. $EXPLANATION"

# Then resolve the thread
gh api graphql -f query='
mutation($threadId: ID!) {
  resolveReviewThread(input: { threadId: $threadId }) {
    thread { id isResolved }
  }
}' -f threadId="$THREAD_ID"
```

For false positives:
```bash
gh api graphql -f query='
mutation($threadId: ID!, $body: String!) {
  addPullRequestReviewThreadReply(input: {
    pullRequestReviewThreadId: $threadId
    body: $body
  }) {
    comment { id }
  }
}' -f threadId="$THREAD_ID" -f body="$EXPLANATION_OF_WHY_NO_CHANGE_NEEDED"

# Then resolve
gh api graphql -f query='
mutation($threadId: ID!) {
  resolveReviewThread(input: { threadId: $threadId }) {
    thread { id isResolved }
  }
}' -f threadId="$THREAD_ID"
```

## Step 6: Verify and Report

1. Run `gh pr checks "$PR_NUMBER"` again to verify CI still passes
2. Fetch threads again to confirm all are resolved
3. Report summary to user: X threads addressed, Y commits made, Z threads resolved

## Key Best Practices

1. **Always push BEFORE replying** - Never reply to comments before fixes are pushed
2. **Use `-f` flag for all gh api variables** - Never use bash variable expansion in the query string
3. **One commit per logical fix** - Don't batch unrelated changes
4. **Skip stale comments** - Check `isOutdated` or `outdated` fields
5. **Verify each step** - Check return codes and status output
6. **Leverage gh-cli skill** - This command builds on the gh-cli skill for GitHub operations
