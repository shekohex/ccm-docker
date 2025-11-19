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

### Updating to Latest Version

To update to the latest claude-code-mux version (v0.6.2+):

```bash
# Pull latest changes
git pull

# Rebuild image with latest upstream version
docker compose build --no-cache

# Restart with new image
docker compose up -d

# Re-authenticate OAuth providers (required after update)
# Visit http://localhost:13456 and authenticate again
```

**Note:** OAuth token format changed in v0.6.2. After updating, you must re-authenticate OAuth providers via the admin UI.

### First-Time Setup

**The proxy works immediately with API key providers** (GLM, Minimax, Kimi). OAuth models (Claude, GPT, Gemini) require authentication:

1. **Configure API keys** in `.env` (required for GLM/Minimax/Kimi)
2. **Authenticate OAuth** at http://localhost:13456 (optional, for Claude/GPT/Gemini)

**Automatic Failover**: OAuth models automatically fall back to GLM models if OAuth is not configured. Once you authenticate OAuth providers, the proxy will use them as the primary models.

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
- **27 Models**: Claude Opus/Sonnet/Haiku, GPT-5.1 variants (12 models), Gemini models (6 models), GLM models, MiniMax M2, Kimi K2
- **Smart Routing**: Automatically routes to best model based on task type
- **Multi-Tier Fallback**: Gemini models cascade through multiple tiers before GLM fallback

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

**Note:** OAuth models automatically fall back to GLM models if OAuth is not configured. See [Router Configuration](#router-configuration) for details.

### Anthropic Claude Models (OAuth, fallback: GLM)
- **claude-opus-4.1** - Most powerful reasoning (uses `think` routing)
- **claude-sonnet-4.5** - Balanced performance (default routing)
- **claude-haiku-4.5** - Fast responses
- **claude-sonnet-3.7** - Alternative Sonnet version

### OpenAI GPT Models (OAuth, fallback: GLM)
- **gpt-5.1** - Latest flagship model (uses `websearch` routing)
- **gpt-5.1-chat-latest** - Chat-optimized variant
- **gpt-5.1-codex** - Full coding model
- **gpt-5.1-codex-mini** - Lightweight coding model
- **gpt-5.1-low** - Low reasoning effort
- **gpt-5.1-medium** - Medium reasoning effort
- **gpt-5.1-high** - High reasoning effort
- **gpt-5.1-codex-low** - Codex with low reasoning
- **gpt-5.1-codex-medium** - Codex with medium reasoning
- **gpt-5.1-codex-high** - Codex with high reasoning
- **gpt-5.1-codex-mini-medium** - Mini codex with medium reasoning
- **gpt-5.1-codex-mini-high** - Mini codex with high reasoning

### Google Gemini Models (OAuth, multi-tier fallback)
- **gemini-3-pro-preview** - Preview of Gemini 3 (fallback: 2.5-pro → 2.5-flash → 2.0-flash → GLM)
- **gemini-2.5-pro** - Most capable Gemini 2.5 (fallback: 2.5-flash → 2.0-flash → GLM)
- **gemini-2.5-flash** - Fast Gemini 2.5 (fallback: 2.0-flash → GLM)
- **gemini-2.0-flash** - Fast Gemini 2.0 (fallback: GLM)
- **gemini-1.5-pro** - Gemini 1.5 Pro (fallback: 1.5-flash → GLM)
- **gemini-1.5-flash** - Fast Gemini 1.5 (fallback: GLM)

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
default = "claude-sonnet-4.5"      # General tasks (→ glm-4.6 if OAuth not configured)
think = "claude-opus-4.1"          # Complex reasoning (→ glm-4.6 fallback)
websearch = "gpt-5.1"              # Web search tasks (→ glm-4.6 fallback)
background = "glm-4.5-air"         # Fast background tasks (API key only)
```

**Task Routing:**
- **default** - All standard requests
- **think** - Requests with extended thinking enabled
- **websearch** - Requests using web search tools
- **background** - Fast, simple tasks (configurable via regex)

**Automatic Failover**: If OAuth is not configured, Claude/GPT models automatically fall back to GLM models (priority 2). Once OAuth is authenticated, requests will use the primary models (priority 1).

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

All OAuth models are configured with automatic failover to GLM models. Gemini models use multi-tier fallback for maximum reliability:

**Simple Failover (Claude/GPT):**
```toml
[[models]]
name = "claude-sonnet-4.5"

# Priority 1: OAuth provider (requires authentication)
[[models.mappings]]
actual_model = "claude-sonnet-4-5-20250929"
priority = 1
provider = "claude-max-main"

# Priority 2: Fallback to GLM if OAuth fails
[[models.mappings]]
actual_model = "glm-4.6"
priority = 2
provider = "zai-coding-plan"
```

**Multi-Tier Failover (Gemini):**
```toml
[[models]]
name = "gemini-3-pro-preview"

# Priority 1: Gemini 3 Pro (OAuth)
[[models.mappings]]
actual_model = "gemini-3-pro-preview"
priority = 1
provider = "gemini-oauth"

# Priority 2: Fallback to Gemini 2.5 Pro
[[models.mappings]]
actual_model = "gemini-2.5-pro"
priority = 2
provider = "gemini-oauth"

# Priority 3: Fallback to Gemini 2.5 Flash
[[models.mappings]]
actual_model = "gemini-2.5-flash"
priority = 3
provider = "gemini-oauth"

# Priority 4: Fallback to Gemini 2.0 Flash
[[models.mappings]]
actual_model = "gemini-2.0-flash"
priority = 4
provider = "gemini-oauth"

# Priority 5: Final fallback to GLM
[[models.mappings]]
actual_model = "glm-4.6"
priority = 5
provider = "zai-coding-plan"
```

**How it works:** The proxy tries providers in priority order. Gemini models cascade through multiple model tiers within OAuth before falling back to GLM, maximizing availability.

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
