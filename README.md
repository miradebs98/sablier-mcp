# Sablier MCP Server

An [MCP (Model Context Protocol)](https://modelcontextprotocol.io) server that lets AI assistants analyze portfolios, stress-test scenarios, and scan SEC filings — in under 2 minutes.

## What This Does

Connect Sablier to Claude, ChatGPT, or any MCP-compatible AI assistant. The agent gets 21 tools to:

**Scan SEC filings & earnings calls** — AI reads every company's 10-K, 10-Q filings and earnings call transcripts, then scores how exposed each holding is to any theme you ask about (0–100 scale with evidence). _"How exposed is my portfolio to China supply chain risk?"_ → scored, evidenced, and ranked in seconds.

**Compute factor exposures** — Measures how each stock responds to market drivers (interest rates, VIX, dollar index, oil, credit spreads, etc.). Factor betas are estimated on a rolling window of recent data so they reflect current market conditions.

**Stress-test with scenarios** — _"What if VIX hits 40?"_ or _"What if the Fed raises rates to 6%?"_ Run simulations to get per-asset expected returns, Value-at-Risk, Expected Shortfall, and full return distributions.

**Manage portfolios** — Create and track portfolios with live prices, performance analytics (Sharpe ratio, max drawdown, volatility), and asset classification (sector, country, industry).

### Speed

> **Under 2 minutes, end-to-end.** Portfolio creation → model training → factor betas → stress scenarios → SEC filing analysis. All in a single conversation.
>
> The same workflow — gathering filings, building factor models, running simulations, writing risk memos — takes a team of analysts and quants **days to weeks**. Sablier compresses it into one chat.

## Quick Start

### Option A: Claude Desktop (recommended — zero install)

Add to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "sablier": {
      "type": "url",
      "url": "https://sablier-mcp-215397666394.us-central1.run.app/mcp/"
    }
  }
}
```

That's it. On first use, Claude opens a browser window — sign up or log in with your Sablier account. No API keys needed.

### Option B: ChatGPT (Developer Mode)

1. Go to **Settings → Developer Mode** and enable it
2. Go to **Connectors → Add connector**
3. Enter:
   - **Name**: `Sablier`
   - **Server URL**: `https://sablier-mcp-215397666394.us-central1.run.app/mcp/`
4. In a new chat, activate via **"+" → More → Developer Mode**

### Option C: Claude Code (local, stdio)

```bash
# Clone and install
git clone https://github.com/miradebs98/sablier-mcp.git
cd sablier-mcp
uv sync

# Register with Claude Code
claude mcp add sablier -- uv --directory /path/to/sablier-mcp run sablier-mcp

# Set your API key (get one from sablier-ai.com)
export SABLIER_API_KEY=sk_live_your_key_here
```

## Tools (21)

### Portfolio Management

| Tool | Description |
|------|-------------|
| `search_features` | Search for tickers (stocks, ETFs) and market indicators (VIX, DXY, rates) |
| `create_portfolio` | Create a portfolio from tickers and weights (must sum to 1.0) |
| `list_portfolios` | List your portfolios with names, assets, and status |
| `get_portfolio` | Get full details for a specific portfolio |
| `update_portfolio` | Update name, description, weights, or capital |
| `get_portfolio_value` | Live portfolio value: total, P&L, per-position breakdown |
| `get_portfolio_analytics` | Sharpe ratio, volatility, max drawdown, beta (1W–5Y timeframes) |
| `get_asset_profiles` | Sector, industry, country, and exchange for each holding |

### Qualitative Analysis (SEC Filings & Earnings Calls)

| Tool | Description |
|------|-------------|
| `analyze_qualitative` | Score company exposure to any theme (0–100) using 10-K, 10-Q, and earnings transcripts |
| `list_themes` | Browse the built-in theme library (AI risk, rate sensitivity, China exposure, etc.) |
| `list_grain_analyses` | List past qualitative analyses |
| `get_grain_analysis` | Load a saved analysis with full scores and evidence passages |

### Quantitative Analysis (Factor Models & Simulation)

| Tool | Description |
|------|-------------|
| `analyze_quantitative` | One-shot: builds factor models, trains them, and computes factor exposures for every asset |
| `list_model_groups` | List existing analyses with training and simulation status |
| `list_feature_set_templates` | Browse pre-built market driver sets (rates, volatility, commodities, credit, etc.) |
| `simulate_betas` | Compute per-asset factor betas from a trained model group |
| `run_model_validation` | Validate model quality: R², autocorrelation, regime sensitivity, pass rate |
| `get_model_validation` | Get cached validation results for a model group |
| `simulate_returns` | Monte Carlo simulation under a what-if scenario → returns VaR, ES, expected return per asset |

### Scenarios

| Tool | Description |
|------|-------------|
| `create_scenario` | Save a named what-if scenario (fixed value, percentile, or std-dev shock) |
| `list_scenarios` | List saved scenarios |

## Example Conversations

### "What happens to my tech portfolio in a recession?"

```
You:   Create a portfolio with AAPL 40%, MSFT 30%, NVDA 30% and stress-test a recession.

Agent: 1. create_portfolio("Tech Portfolio", ["AAPL", "MSFT", "NVDA"], [0.4, 0.3, 0.3])
       2. analyze_quantitative(portfolio_id, conditioning_set_id)  →  factor betas per asset
       3. simulate_returns(sim_batch_id, {"VIX": 35, "US 10Y": 5.5, "SPY": 380})
          → per-asset VaR, Expected Shortfall, return distributions
```

### "How exposed is Apple to China risk?"

```
You:   Analyze AAPL's exposure to China supply chain and China revenue risk.

Agent: 1. analyze_qualitative(tickers=["AAPL"], themes=["China supply chain risk", "China revenue exposure"])
       2. Returns:
          - China supply chain risk: 78/100 (HIGH) — evidence from 10-K mentioning
            "substantially all iPhone final assembly in China" + earnings call discussing
            diversification to India
          - China revenue exposure: 65/100 (SIGNIFICANT) — Greater China = 19% of revenue
```

### "Compare defensive vs. growth in a rate hike"

```
You:   Build a defensive portfolio (JNJ, PG, KO) and a growth portfolio (TSLA, SHOP, SNOW).
       Compare them if rates jump to 6%.

Agent: 1. Creates both portfolios
       2. Runs analyze_quantitative on each
       3. simulate_returns with {"FED_FUNDS": 6.0, "US 10Y": 5.5} for both
       4. Compares: defensive VaR = -3.2% vs growth VaR = -11.8%
```

## Architecture

```
sablier-mcp/
├── src/sablier_mcp/
│   ├── server.py      # 21 MCP tool definitions (FastMCP)
│   ├── client.py      # Async HTTP client for Sablier API
│   ├── auth.py        # OAuth 2.0 provider (remote mode)
│   └── widgets.py     # Rich HTML cards for Claude Desktop
├── pyproject.toml
├── Dockerfile
└── README.md
```

- **Remote mode** (Claude Desktop, ChatGPT): OAuth 2.0 browser login — no API keys to manage
- **Local mode** (Claude Code, stdio): API key from environment variable
- **Widgets**: Tools return rich HTML cards (beta heatmaps, score cards, portfolio overviews) alongside text for visual output in Claude Desktop

## Development

```bash
# Run the server locally (stdio transport)
uv run sablier-mcp

# Test with MCP inspector
npx @modelcontextprotocol/inspector uv --directory . run sablier-mcp

# Run as remote server (streamable-http with OAuth)
MCP_TRANSPORT=streamable-http uv run sablier-mcp
```

## Links

- **Sablier Platform**: [sablier-ai.com](https://sablier-ai.com)
- **MCP Protocol**: [modelcontextprotocol.io](https://modelcontextprotocol.io)
