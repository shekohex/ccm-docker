# CCM Docker

Docker setup for **[Claude Code Mux](https://github.com/9j/claude-code-mux)** - intelligent model routing proxy for Claude Code with multi-provider support and automatic failover.

> **Note:** This is an unofficial Docker wrapper. For the official project, documentation, and features, visit [9j/claude-code-mux](https://github.com/9j/claude-code-mux).

## About Claude Code Mux

Claude Code Mux is a lightweight Rust-powered proxy that enables:
- Multi-model routing (use different AI models for different tasks)
- Provider failover (automatic backup when primary fails)
- OAuth support (free API access for Claude Pro/Max, ChatGPT Plus/Pro, Google AI Pro/Ultra)
- 18+ provider support (Anthropic, OpenAI, Google, Groq, OpenRouter, etc.)
- Intelligent routing by task type (websearch, reasoning, background, default)

See the [official repository](https://github.com/9j/claude-code-mux) for complete features and documentation.

## Quick Start

```bash
git clone https://github.com/shekohex/ccm-docker
cd ccm-docker

docker compose up -d

docker compose logs -f
```

Access the admin UI at: http://localhost:13456

## Configuration

### Volume Structure

- **`./config`** → `/config` in container
  - `config.toml` - Main configuration file

- **`ccm-data`** → `/data` in container (named volume)
  - `oauth_tokens.json` - OAuth authentication tokens
  - `ccm.log` - Application logs
  - `ccm.pid` - Process ID file

### Editing Configuration

Edit `./config/config.toml` on your host machine:

```toml
[server]
host = "127.0.0.1"
port = 13456
log_level = "info"

[router]
default = "my-model"
think = "reasoning-model"
websearch = "search-model"
background = "fast-model"

[[providers]]
name = "openrouter"
provider_type = "openrouter"
enabled = true
api_key = "sk-or-v1-..."
models = []

[[models]]
name = "my-model"

[[models.mappings]]
provider = "openrouter"
actual_model = "anthropic/claude-sonnet-4.5"
priority = 1
```

Restart after config changes:
```bash
docker compose restart
```

## Provider Configuration

### Adding a Provider

1. Edit `./config/config.toml`
2. Add provider entry:

```toml
[[providers]]
name = "my-provider"
provider_type = "openai"
enabled = true
api_key = "sk-..."
models = []
```

**Supported provider types:**
- `anthropic` - Anthropic API
- `openai` - OpenAI API
- `openrouter` - OpenRouter
- `groq` - Groq
- `z.ai` - z.ai
- `zenmux` - ZenMux
- `minimax` - Minimax
- `kimi` - Kimi
- `gemini` - Google Gemini
- `vertex-ai` - Google Vertex AI

### OAuth Configuration

OAuth tokens are stored in `/data/oauth_tokens.json`. Use the web UI at http://localhost:13456 to set up OAuth authentication for:
- Claude Pro/Max (free API access)
- ChatGPT Plus/Pro (free API access)
- Google AI Pro/Ultra (free API access)

## Model Configuration

### Adding a Model

```toml
[[models]]
name = "fast-model"

[[models.mappings]]
provider = "provider-name"
actual_model = "provider/model-id"
priority = 1
```

### Failover Configuration

```toml
[[models]]
name = "reliable-model"

[[models.mappings]]
provider = "primary-provider"
actual_model = "model-id"
priority = 1

[[models.mappings]]
provider = "backup-provider"
actual_model = "model-id"
priority = 2
```

## Routing Configuration

```toml
[router]
default = "model-for-general-tasks"
think = "model-for-reasoning"
websearch = "model-for-web-search"
background = "model-for-simple-tasks"
```

**Routing logic:**
- **WebSearch**: Requests with `web_search` tool
- **Think**: Requests with `thinking` field enabled
- **Background**: Background tasks (configurable regex)
- **Default**: All other requests

## Docker Commands

### Build and Start
```bash
docker compose up -d
```

### View Logs
```bash
docker compose logs -f
```

### Restart Service
```bash
docker compose restart
```

### Stop Service
```bash
docker compose down
```

### Rebuild Image
```bash
docker compose build --no-cache
```

### Access Container Shell
```bash
docker compose exec ccm sh
```

## Environment Variables

- `CCM_CONFIG_DIR` - Config directory (default: `/config`)
- `CCM_DATA_DIR` - Data directory (default: `/data`)

## Using with Claude Code

Configure Claude Code to use the proxy:

```bash
export ANTHROPIC_BASE_URL="http://localhost:13456"
export ANTHROPIC_API_KEY="any-string"
claude
```

Or in your Claude Code config:
```json
{
  "anthropicBaseUrl": "http://localhost:13456",
  "anthropicApiKey": "any-string"
}
```

## Troubleshooting

### Check container status
```bash
docker compose ps
```

### View real-time logs
```bash
docker compose logs -f ccm
```

### Check health
```bash
docker compose exec ccm curl http://localhost:13456/api/config/json
```

### Reset data
```bash
docker compose down -v
docker compose up -d
```

### Configuration not loading
Ensure `./config/config.toml` exists and has valid TOML syntax:
```bash
docker compose exec ccm ccm --version
docker compose exec ccm cat /config/config.toml
```

## Port Conflicts

If port 13456 is in use, modify `compose.yml`:
```yaml
ports:
  - "8080:13456"
```

Then set `ANTHROPIC_BASE_URL=http://localhost:8080`

## Security Notes

- OAuth tokens stored in `/data` volume with restricted permissions
- Container runs as non-root user (UID 1000)
- Only port 13456 exposed
- Config files readable only by container user

## Admin UI

Web interface available at: http://localhost:13456

Features:
- Provider management
- Model configuration
- Router setup
- Live testing
- OAuth token management

## Performance

- **Image size:** ~10MB (Alpine + musl binary)
- **Memory:** ~6MB RAM
- **Startup:** <100ms
- **Routing overhead:** <1ms per request

## Links

**Original Project:**
- [Claude Code Mux GitHub](https://github.com/9j/claude-code-mux)
- [Official Documentation](https://github.com/9j/claude-code-mux#readme)
- [Report Issues](https://github.com/9j/claude-code-mux/issues)

**This Docker Wrapper:**
- Docker-specific issues: [Create Issue](https://github.com/shekohex/ccm-docker/issues)

## License

This Docker wrapper is provided as-is. Claude Code Mux is licensed under MIT - see the [original project](https://github.com/9j/claude-code-mux) for details.
