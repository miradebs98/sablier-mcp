# Sablier MCP Server

An [MCP (Model Context Protocol)](https://modelcontextprotocol.io) server that gives AI agents access to Sablier's regime-dependent factor modeling, qualitative analysis, and portfolio risk testing.

## What This Does

When connected to an AI assistant (Claude, GPT, etc.), the agent can:

- **Analyze portfolios qualitatively** — GRAIN analysis scores ticker exposure to themes like "AI risk", "China dependency", or "rate sensitivity" using SEC filings and earnings transcripts
- **Compute regime-dependent factor betas** — Unlike static MSCI betas, Sablier's betas change with market conditions (trained with Mamba SSM)
- **Simulate return distributions** — Monte Carlo sampling under any factor scenario (recession, rate hike, etc.)
- **Test portfolio risk** — VaR, CVaR, risk contribution, diversification ratio

## Quick Start

### 1. Get a Sablier API Key

Sign up at [sablier.io](https://sablier.io) and generate an API key from the dashboard.

### 2. Install

```bash
# Using uv (recommended)
cd sablier-mcp
uv sync

# Or pip
pip install -e .
```

### 3. Configure

Create a `.env` file:

```
SABLIER_API_KEY=sk_live_your_key_here
```

### 4. Add to Claude Desktop

Add to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "sablier": {
      "command": "uv",
      "args": ["--directory", "/path/to/sablier-mcp", "run", "sablier-mcp"],
      "env": {
        "SABLIER_API_KEY": "sk_live_your_key_here"
      }
    }
  }
}
```

### 5. Add to Claude Code

```bash
claude mcp add sablier -- uv --directory /path/to/sablier-mcp run sablier-mcp
```

Set the env variable:
```bash
export SABLIER_API_KEY=sk_live_your_key_here
```

## Available Tools

| Tool | Description |
|------|-------------|
| `search_features` | Search for tickers and market features (VIX, rates, etc.) |
| `create_portfolio` | Create a portfolio from tickers and weights |
| `list_portfolios` | List existing portfolios |
| `get_portfolio` | Get portfolio details |
| `analyze_qualitative` | Run GRAIN analysis on tickers for themes (auto-polls) |
| `get_analysis_status` | Check GRAIN analysis progress |
| `list_model_groups` | List model groups with training/simulation status |
| `list_feature_set_templates` | List available conditioning set templates |
| `create_models` | Batch create per-asset factor models |
| `train_models` | Start batch training (GPU, 5-30 min) |
| `get_training_progress` | Check training progress |
| `simulate_betas` | Compute regime-dependent factor betas (auto-polls) |
| `get_betas_results` | Get detailed beta results |
| `simulate_returns` | Sample return distributions under a scenario (auto-polls) |
| `get_returns_results` | Get returns simulation results |
| `test_portfolio_risk` | Portfolio VaR, CVaR, risk decomposition |
| `create_scenario` | Create a named what-if scenario |
| `list_scenarios` | List existing scenarios |

## Example Conversations

### "What happens to my tech portfolio in a recession?"

The agent would:
1. `create_portfolio("Tech Portfolio", ["AAPL", "MSFT", "NVDA"], [0.4, 0.3, 0.3])`
2. Use existing trained models → `list_model_groups()`
3. `simulate_betas(model_group_id)` → regime-dependent factor exposures
4. `simulate_returns(sim_batch_id, {"VIX": 35, "DXY": 95, "TLT": 3.0})` → recession scenario
5. `test_portfolio_risk(sim_batch_id, weights)` → VaR, CVaR, risk breakdown

### "How exposed is Apple to China risk?"

The agent would:
1. `analyze_qualitative(["AAPL"], ["China supply chain risk", "China revenue exposure"])`
2. Returns scores, evidence passages from 10-K filings, and confidence levels

### "Compare defensive vs. growth portfolio in a rate hike"

The agent would:
1. Create both portfolios
2. Simulate betas for each
3. Run returns under `{"FED_FUNDS": 6.0, "TLT": 5.5}` scenario
4. Compare VaR, expected returns, risk decomposition

## Architecture

```
sablier-mcp/
├── src/sablier_mcp/
│   ├── __init__.py
│   ├── server.py      # MCP tool definitions (FastMCP)
│   └── client.py      # Async HTTP client for Sablier API
├── pyproject.toml
├── .env.example
└── README.md
```

The MCP server is a thin wrapper over the Sablier REST API. It:
- Authenticates with API keys (`sk_live_...`)
- Handles async job polling (GRAIN analysis, simulations)
- Formats responses for AI readability
- Provides workflow guidance in tool descriptions

## Development

```bash
# Run the server directly (stdio transport)
uv run sablier-mcp

# Test with MCP inspector
npx @modelcontextprotocol/inspector uv --directory . run sablier-mcp
```
