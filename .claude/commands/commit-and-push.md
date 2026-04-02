---
description: Review changes, write a Conventional Commit message, ask for confirmation, then commit and push.
---

Follow this workflow exactly:

1. Check the current Git branch.
2. Analyze all staged and unstaged changes using:
   - `git diff --staged`
   - `git diff`

3. Generate a high-quality commit message using Conventional Commits.
   Requirements:
   - Maximum of 3 lines total.
   - First line must be: `<type>: <specific summary>`
   - Allowed types include: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `build`, `ci`, `perf`
   - Add a second and/or third line only when useful for important context
   - Avoid vague messages like `update` or `fix stuff`
   - Be specific about the actual change

4. Show the user:
   - the current branch
   - the proposed commit message

5. Ask for explicit confirmation before running any write or push command.

6. If the user confirms, execute:
   - `git add .`
   - `git commit` using the generated message
   - `git push origin main`

7. If the commit message has multiple lines, preserve them correctly when running `git commit`.

8. If the user does not confirm, stop immediately and do not run any commands.

Important behavior:

- Do not skip the diff review.
- Do not invent changes not supported by the diff.
- Do not run `git add`, `git commit`, or `git push` until the user clearly confirms.
- Keep the response concise and actionable.
