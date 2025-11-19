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

# Copy and configure environment variables
cp .env.example .env
# Edit .env with your API keys

# Start the service
docker compose up -d

# View logs
docker compose logs -f
```

Access the admin UI at: http://localhost:13456

### Environment Variables

Create a `.env` file from the example:

```bash
cp .env.example .env
```

Edit `.env` and add your API keys:

```bash
# Required for GLM models (glm-4.6, glm-4.5-air, glm-4.5v)
ZAI_API_KEY=your-zai-api-key-here

# Required for MiniMax-M2 model
MINIMAX_API_KEY=your-minimax-api-key-here

# Required for kimi-k2-thinking model
KIMI_API_KEY=your-kimi-api-key-here
```

**OAuth providers** (Anthropic, OpenAI, Gemini) are configured via the web UI at http://localhost:13456 - no environment variables needed.

## Configuration

### Volume Structure

- **`./config`** → `/config` in container (bind mount)
  - `config.toml` - Main configuration file

- **`ccm-data`** → `/home/ccm/.claude-code-mux` in container (named volume)
  - `oauth_tokens.json` - OAuth authentication tokens
  - `ccm.pid` - Process ID file
  - Logs are sent to stdout/stderr (view with `docker compose logs`)

### Editing Configuration

Edit `./config/config.toml` on your host machine. The default config includes:

- **6 Providers**: Anthropic (OAuth), OpenAI (OAuth), Gemini (OAuth), Z.AI (API key), Minimax (API key), Kimi (API key)
- **16 Models**: Claude Opus/Sonnet/Haiku, GPT-5.1 variants, Gemini 2.5/3, GLM models, MiniMax M2, Kimi K2
- **Smart Routing**: Automatically routes to best model based on task type

Restart after config changes:
```bash
docker compose restart
```

See [Available Models](#available-models) and [Router Configuration](#router-configuration) sections for details.

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
- `anthropic` - Anthropic API (supports OAuth)
- `openai` - OpenAI API (supports OAuth)
- `gemini` - Google Gemini (supports OAuth and API key)
- `z.ai` - Z.AI (API key for GLM models)
- `minimax` - Minimax (API key)
- `kimi-coding` - Kimi/Moonshot (API key)
- `openrouter` - OpenRouter
- `groq` - Groq
- `zenmux` - ZenMux
- `vertex-ai` - Google Vertex AI

### OAuth Configuration

OAuth tokens are stored in the `ccm-data` volume at `/home/ccm/.claude-code-mux/oauth_tokens.json`.

Use the web UI at http://localhost:13456 to set up OAuth authentication for:
- **Anthropic Claude Pro/Max** - Free API access to Claude models
- **OpenAI ChatGPT Plus/Pro/Codex** - Free API access to GPT-5.1 models
- **Google Gemini AI Pro/Ultra** - Free API access to Gemini 2.5 & 3 models

OAuth setup is done entirely through the web UI - no environment variables or API keys needed.

## Available Models

The default configuration includes the following models:

### Anthropic Claude Models (OAuth)
- **claude-opus-4.1** - Most powerful reasoning (uses `think` routing)
- **claude-sonnet-4.5** - Balanced performance (default routing)
- **claude-haiku-4.5** - Fast responses
- **claude-sonnet-3.7** - Alternative Sonnet version

### OpenAI GPT Models (OAuth)
- **gpt-5.1** - Latest flagship model (uses `websearch` routing)
- **gpt-5.1-chat-latest** - Chat-optimized variant
- **gpt-5.1-codex-mini** - Lightweight coding model

### Google Gemini Models (OAuth)
- **gemini-2.5-pro** - Most capable Gemini model
- **gemini-2.5-flash** - Fast responses
- **gemini-3-pro-preview** - Preview of Gemini 3

### ZhipuAI/GLM Models (API Key via Z.AI)
- **glm-4.6** - Latest GLM model
- **glm-4.5-air** - Lightweight, fast (uses `background` routing)
- **glm-4.5v** - Vision-capable variant

### Minimax Models (API Key)
- **minimax-m2** - MiniMax M2 model

### Kimi/Moonshot Models (API Key)
- **kimi-k2-thinking** - Reasoning-capable model

## Router Configuration

The router automatically selects models based on task type:

```toml
[router]
default = "claude-sonnet-4.5"      # General tasks
think = "claude-opus-4.1"          # Complex reasoning
websearch = "gpt-5.1"              # Web search tasks
background = "glm-4.5-air"         # Fast background tasks
```

**Task Routing:**
- **default** - All standard requests
- **think** - Requests with extended thinking enabled
- **websearch** - Requests using web search tools
- **background** - Fast, simple tasks (configurable via regex)

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

## Data Persistence

All runtime data (OAuth tokens, PID files) is stored in the `ccm-data` named volume, mounted at `/home/ccm/.claude-code-mux` inside the container. This ensures data persists across container restarts.

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

- OAuth tokens stored in named volume `/home/ccm/.claude-code-mux` with permissions 0600
- Container runs as non-root user `ccm` (UID 1000)
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
