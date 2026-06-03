# AOne UI

AOne UI is a Flutter interface for agentic AI workflows: chat sessions,
projects, active agents, task boards, history, and feedback.

The original route and transportation surfaces have been removed from this copy
so the app can focus on AI agent coordination.

## Docker Web Image

Build and run the local Flutter web UI image:

```bash
docker build -t efexzium/aone-ui:dev .
docker run -d --name aone-ui-dev -p 8080:80 efexzium/aone-ui:dev
```

Then open:

```text
http://127.0.0.1:8080
```
