# Go CLI E2E Profile

- Start the CLI through its public entry point, normally as a built binary or `go run` command.
- Provide deterministic stdin and capture stdout, stderr, and the process exit status.
- Configure external endpoints through the application's supported configuration surface.
- Use a controlled HTTP server when validating the CLI flow independently of a real backend.
- Bound process execution with a timeout and always clean up child processes.
- Run the targeted package or test selected by the project's test command.
