<p align="center">
  <img src="https://github.com/user-attachments/assets/4acbdd65-1399-4281-a452-47edaecf4542" alt="Claude Bug Bounty Logo" width="320"/>
</p>

<div align="center">

<img src="https://img.shields.io/badge/v3.1.0-Caido_Edition-blueviolet?style=for-the-badge" alt="v3.1.0">

# Hocaido Bug Hunter

### Find security vulnerabilities, get paid with AI doing the Hard Work
#### The free spirit of a new challenge.

*Your AI hunting partner that remembers past targets, spots vulnerabilities, and writes reports for you.*
<br>

<br>

[![Python 3.8+](https://img.shields.io/badge/Python-3.8+-3776AB.svg?style=flat-square&logo=python&logoColor=white)](https://python.org)
[![Tests](https://img.shields.io/badge/Tests-129_passing-brightgreen.svg?style=flat-square)](tests/)
[![Claude Code](https://img.shields.io/badge/Claude_Code-Plugin-D97706.svg?style=flat-square&logo=anthropic&logoColor=white)](https://claude.ai/claude-code)
[![Caido](https://img.shields.io/badge/Proxy-Caido-FF6F00.svg?style=flat-square)](https://caido.io)

<br>

<a href="#what-is-this">What Is This?</a>&nbsp;&nbsp;|&nbsp;&nbsp;<a href="#quick-start">Quick Start</a>&nbsp;&nbsp;|&nbsp;&nbsp;<a href="#commands">Commands</a>&nbsp;&nbsp;|&nbsp;&nbsp;<a href="#whats-new">What's New</a>&nbsp;&nbsp;|&nbsp;&nbsp;<a href="#installation">Install</a>&nbsp;&nbsp;|&nbsp;&nbsp;<a href="#faq">FAQ</a>

<br>

</div>

<br>

---
<div align="center">

  [![Watch video](https://img.youtube.com/vi/9kFjllySzdI/hqdefault.jpg)](https://www.youtube.com/watch?v=9kFjllySzdI)
  
</div>
<br>

## What Is This?

Bug bounty hunting is when companies pay you real money to find security vulnerabilities in their websites and apps before bad actors do. Platforms like **HackerOne** and **Bugcrowd** connect hunters with companies. Payouts range from **$100 to $1,000,000+** depending on severity.

This tool is a plugin for **Claude Code** (Anthropic's AI coding assistant) that turns it into a professional bug bounty hunting partner. Instead of juggling 15 different tools and writing reports from scratch, you just type a command and the AI handles the rest.

**In plain terms:**

- You give it a target website
- It automatically scans the site, finds vulnerabilities, validates they're real, and writes a professional report
- It remembers what you found on past targets and applies that knowledge to new ones
- You can even put it on autopilot and let it hunt on its own while you sleep
- It plugs directly into **[Caido](https://caido.io)** — the modern web proxy — so Claude can see your live browsing traffic, search HTTP history with HTTPQL, and replay authenticated requests with one command

**Who is it for?**

- Security researchers who want to move faster
- Bug bounty hunters who are tired of the manual grind
- People learning security who want AI guidance at every step

<br>

---

<br>

## The Problem (Before This Tool)

Most hunters waste hours on things that shouldn't take that long:

- Manually running 10+ tools in the right order just to map a target
- Writing the same report structure from scratch every single time (45 min each)
- Forgetting that a technique worked on a similar target 3 months ago
- Submitting bugs that get rejected because they weren't properly validated first
- Jumping between terminal windows, browser, Caido, notes, and report drafts
- Copy-pasting 2KB of session cookies from Caido into curl over and over

<br>

## The Solution (After This Tool)

<div align="center">

| Before | After |
|:---|:---|
| Run 10+ tools manually, hope for the best | AI orchestrates everything in the right order |
| Write reports from scratch (45 min each) | `report-writer` agent generates submission-ready reports in 60s |
| Forget what worked last month | Memory system — patterns from target A inform target B |
| Submit bugs without proper validation | 7-Question Gate kills weak findings before you waste time reporting |
| Copy-paste cookies into curl | **Caido MCP + `caido-mode` skill** — Claude finds your authenticated request, edits the path/body, replays it |
| Can't see live browser traffic | Caido HTTP history search via HTTPQL — Claude reads your proxy in real time |
| Hunt one endpoint at a time | `/autopilot` runs the full hunt loop while you watch |

</div>

<br>

---

<br>

## Quick Start

> **Prerequisite:** [Claude Code](https://claude.ai/claude-code) installed, plus [Caido](https://caido.io) running locally (free tier works, Individual recomended)
>                  <br> Please make sure that you have configure the following mcp before using Claude code. 
>                  <br> https://github.com/Sicks3c/hackerone-mcp-server | https://github.com/c0tton-fluff/caido-mcp-server | https://github.com/caido/skills
>                  <br> Do not use the caido-mode without adding the following library and variable below in the file caido-client.ts in the folder caido-mode:

```bash
                          import WebSocket from "ws";
                          global.WebSocket = WebSocket;
```

**Step 1 — Install tools + skills**

```bash
git clone https://github.com/shuvonsec/claude-bug-bounty.git
cd claude-bug-bounty

chmod +x install_tools.sh && ./install_tools.sh   # scanning tools (subfinder, httpx, nuclei…) + Caido desktop/CLI
chmod +x install.sh        && ./install.sh        # AI skills + commands + Caido/HackerOne MCPs
```

**Step 2 — Configure your credentials** *(never shipped in the repo)*

```bash
export CAIDO_PAT=caido_xxx           # Caido → Dashboard → Developer → Personal Access Tokens
export H1_USERNAME=<your-h1-user>    # optional — enables HackerOne MCP
export H1_API_TOKEN=<your-h1-token>

./install.sh                         # re-run to register MCPs now that creds are set
```

**Step 3 — Initialize the Caido skill** *(one-time, uses your PAT)*

```bash
npx tsx ~/.claude/skills/caido-mode/caido-client.ts setup "$CAIDO_PAT"
npx tsx ~/.claude/skills/caido-mode/caido-client.ts health
```

**Step 4 — Start hunting**

```bash
claude                          # open Claude Code in your terminal

/recon target.com               # step 1: map the target (subdomains, live pages, URLs)
/hunt target.com                # step 2: test for vulnerabilities (Claude reads your Caido history as it goes)
/validate                       # step 3: make sure the finding is real before writing it up
/report                         # step 4: generate a professional submission report
```

That's the core loop. Four commands, full workflow.

**Step 5 — Go autonomous**

```bash
/autopilot target.com --normal  # AI runs the whole loop, pauses for your review at the end
/resume target.com              # continue where you left off on a previous target
/intel target.com               # get CVEs + disclosed reports relevant to this target
```

> **Don't use Claude Code?** Run the Python tools directly:
> ```bash
> python3 tools/hunt.py --target target.com
> ./tools/recon_engine.sh target.com
> ```

<br>

---

<br>

## How It Works

Think of it like a team of specialists, each doing one job:

<p align="center">
  <img width="400" src="https://github.com/user-attachments/assets/308b242f-e8f9-4945-bef0-8b24661ae298" />
</p>

Each step feeds the next. Claude orchestrates all of it, or you run any step on its own.

<br>

---

<br>

## Caido Integration — in detail

Caido is the modern open-source web proxy (think Burp, but scriptable). This project plugs into Caido two ways:

### 1. `caido-mode` skill — Claude has a full CLI into your proxy

Installed to `~/.claude/skills/caido-mode/`. Auth uses your PAT (env var `CAIDO_PAT` or cached via `setup`).

| Category | What Claude can do |
|:---|:---|
| **HTTP History** | `search`, `recent`, `get`, `get-response`, `export-curl` (HTTPQL queries) |
| **Edit & Replay** | `edit` (change path/method/body/headers while keeping cookies + auth) · `replay` · `send-raw` |
| **Sessions / Collections** | Save authenticated base requests, group them by feature |
| **Scopes** | `create-scope` with allowlist/denylist before you start testing |
| **Filter Presets** | Save HTTPQL filters (e.g. `resp.code.gte:400 AND req.path.cont:"/api/"`) |
| **Environments** | Store victim IDs, tokens, test vars, swap between them |
| **Findings** | `create-finding` straight from Claude into Caido UI |
| **Fuzzing** | `create-automate-session` + `fuzz` against a base request |
| **Intercept** | `intercept-enable`/`-disable` programmatically |

**Why this matters:** session cookies + JWTs can be 2KB. Instead of copy-pasting them into curl, Claude finds an organic request in your Caido history that already has valid auth, then calls `edit` to change just the path or body. Full response comes back, and the request appears in Caido for further manual analysis.

```bash
# What Claude actually runs under the hood (you don't type this):
npx tsx ~/.claude/skills/caido-mode/caido-client.ts search 'req.path.cont:"/api/users/" AND resp.code.eq:200'
npx tsx ~/.claude/skills/caido-mode/caido-client.ts edit <id> --path /api/users/999   # IDOR test
npx tsx ~/.claude/skills/caido-mode/caido-client.ts export-curl <id>                  # PoC for the report
```

### 2. Caido MCP server — native tools for Claude Code

`mcp/caido-mcp-server-main/` is registered as an MCP at install time. Claude Code gets native tool calls for every Caido operation — no shell invocation needed. The MCP and the skill share the same PAT; they give Claude two routes to the same proxy so it always has fallback.

<br>

---

<br>

## Commands

### The Core 4 *(start here)*

| Command | What It Does | When To Use |
|:---|:---|:---|
| `/recon target.com` | Maps the target — subdomains, live pages, APIs, basic scans | Always first |
| `/hunt target.com` | Actively tests for vulnerabilities using the right technique for the tech stack | After recon |
| `/validate` | Runs a 7-question check to confirm a finding is real before writing it up | Before every report |
| `/report` | Generates a professional submission report for H1/Bugcrowd/Intigriti/Immunefi | After validation |

### Power Commands

| Command | What It Does |
|:---|:---|
| `/autopilot target.com` | AI runs the full loop automatically — recon → hunt → validate → report |
| `/surface target.com` | Shows a ranked list of the best places to test (based on your past findings) |
| `/resume target.com` | Shows untested endpoints from last session and picks up where you left off |
| `/remember` | Saves the current finding or technique to memory for future use |
| `/intel target.com` | Pulls CVEs and past disclosed reports relevant to this target |
| `/chain` | When you find bug A, this finds bugs B and C that usually come with it |
| `/scope <asset>` | Checks if a domain or URL is in scope before you test it |
| `/triage` | Quick 2-minute go/no-go check — should you keep investigating or move on? |
| `/web3-audit <contract>` | Full smart contract security audit with 10 bug class checklist |
| `/token-scan <contract>` | Scans a meme coin or token for rug pull signals (EVM + Solana) |

<br>

---

<br>

## AI Agents

8 specialized agents, each built for one job:

| Agent | What It Does | Model |
|:---|:---|:---|
| **recon-agent** | Finds all subdomains, live hosts, and URLs for a target | Haiku *(fast)* |
| **report-writer** | Writes professional, impact-first reports that get paid | Opus *(quality)* |
| **validator** | Runs the 7-Question Gate — kills weak findings before you waste time | Sonnet |
| **web3-auditor** | Audits smart contracts for 10 common vulnerability classes | Sonnet |
| **chain-builder** | When you find one bug, finds the chain of related bugs | Sonnet |
| **autopilot** | Runs the whole hunt loop autonomously with safety checkpoints | Sonnet |
| **recon-ranker** | Ranks the attack surface so you test the highest-value targets first | Haiku *(fast)* |
| **token-auditor** | Fast meme coin / token rug pull and security analysis | Sonnet |

<br>
---

## 7-Question Gate — Bug Killer

  Ask **in order**. One wrong answer = STOP, kill it, move on.

  | # | Question | KILL if... |
  |---|----------|------------|
  | **Q1** | Can an attacker use this RIGHT NOW, step by step? Fill: Setup → exact HTTP request → Result → Impact →
  Cost. | You can't write step 2 as a concrete `curl`-ready HTTP request. |
  | **Q2** | Is the impact on the program's accepted list? | Maps to a listed exclusion ("out of scope bugs"). |
  | **Q3** | Is the root cause in an in-scope asset? | It's a third-party SaaS (Stripe/Salesforce/Auth0),
  staging/internal, or not on the scope list. |
  | **Q4** | Does it require privileged access the attacker can't get? | "Admin can do X" = centralization risk, not a
  bug. Physical access / victim's MFA device / already-compromised account = invalid. |
  | **Q5** | Already known or accepted behavior? | Found in disclosed reports, GitHub security issues, changelog, or API
   docs as "by design". |
  | **Q6** | Can you prove impact beyond "technically possible"? | Only have `alert(1)`, DNS ping, or 200 status — no
  actual data exfil, cookie theft, or internal service response. → **Downgrade, don't kill.** |
  | **Q7** | Known-invalid bug class? | On the NEVER-SUBMIT list with no chain (missing headers, self-XSS, logout CSRF,
  open redirect alone, SSRF DNS-only, clickjacking on non-sensitive pages, etc.). |

---

<br>

## What's New

<details>
<summary><b>Caido Integration</b> — replaces Burp, gains scriptability</summary>
<br>

- **`caido-mode` skill** — Full SDK CLI for searching history (HTTPQL), editing + replaying authenticated requests, managing scopes/filters/environments, creating findings, and fuzzing
- **Caido MCP server** — native Claude Code tools for every proxy operation
- **Auth via PAT** — set `CAIDO_PAT` once, everything works from both the skill and the MCP
- **Two routes, one proxy** — the skill and MCP share creds; Claude always has fallback

</details>

<details>
<summary><b>Autonomous Hunt Loop</b> — <code>/autopilot</code></summary>
<br>

7-step loop that runs continuously: **scope → recon → rank → hunt → validate → report → checkpoint**

Three checkpoint modes:
- `--paranoid` — stops after every finding for your review
- `--normal` — batches findings, checkpoints every few minutes
- `--yolo` — minimal stops (still requires approval for report submissions)

Built-in safety: circuit breaker stops hammering hosts after consecutive failures, per-host rate limiting, every request logged to `audit.jsonl`.

</details>

<details>
<summary><b>Persistent Hunt Memory</b> — remember everything</summary>
<br>

- **Journal** — append-only JSONL log of every hunt action (concurrent-safe writes)
- **Pattern DB** — what technique worked on which tech stack, sorted by payout
- **Target profiles** — tested/untested endpoints, tech stack, findings
- **Cross-target learning** — patterns from target A suggested when hunting target B

</details>

<details>
<summary><b>HackerOne MCP</b></summary>
<br>

Public API integration:
- `search_disclosed_reports` — search Hacktivity by keyword or program
- `get_program_stats` — bounty ranges, response times, resolved counts
- `get_program_policy` — scope, safe harbor, excluded vuln classes

</details>

<details>
<summary><b>On-Demand Intel</b> — <code>/intel</code></summary>
<br>

Wraps `learn.py` + HackerOne MCP + hunt memory:
- Flags **untested CVEs** matching the target's tech stack
- Shows **new endpoints** not in your tested list
- Surfaces **cross-target patterns** from your own hunt history
- Prioritizes: CRITICAL untested > HIGH untested > already tested

</details>

<details>
<summary><b>Deterministic Scope Safety</b></summary>
<br>

`scope_checker.py` uses anchored suffix matching — code check, not LLM judgment:
- `*.target.com` matches `api.target.com` but NOT `evil-target.com`
- Excluded domains always win over wildcards
- IP addresses rejected with warning (match by domain only)
- Every test filtered through scope before execution

</details>

<br>

---

<br>

## Vulnerability Coverage

<details>
<summary><b>20 Web2 Bug Classes</b> — click to expand</summary>
<br>

| Class | Key Techniques | Typical Payout |
|:---|:---|:---|
| **IDOR** | Object-level, field-level, GraphQL node(), UUID enum, method swap | $500 - $5K |
| **Auth Bypass** | Missing middleware, client-side checks, BFLA | $1K - $10K |
| **XSS** | Reflected, stored, DOM, postMessage, CSP bypass, mXSS | $500 - $5K |
| **SSRF** | Redirect chain, DNS rebinding, cloud metadata, 11 IP bypasses | $1K - $15K |
| **Business Logic** | Workflow bypass, negative quantity, price manipulation | $500 - $10K |
| **Race Conditions** | TOCTOU, coupon reuse, limit overrun, double spend | $500 - $5K |
| **SQLi** | Error-based, blind, time-based, ORM bypass, WAF bypass | $1K - $15K |
| **OAuth/OIDC** | Missing PKCE, state bypass, 11 redirect_uri bypasses | $500 - $5K |
| **File Upload** | Extension bypass, MIME confusion, polyglots, 10 bypasses | $500 - $5K |
| **GraphQL** | Introspection, node() IDOR, batching bypass, mutation auth | $1K - $10K |
| **LLM/AI** | Prompt injection, chatbot IDOR, ASI01-ASI10 framework | $500 - $10K |
| **API Misconfig** | Mass assignment, JWT attacks, prototype pollution, CORS | $500 - $5K |
| **ATO** | Password reset poisoning, token leaks, 9 takeover paths | $1K - $20K |
| **SSTI** | Jinja2, Twig, Freemarker, ERB, Thymeleaf -> RCE | $2K - $10K |
| **Subdomain Takeover** | GitHub Pages, S3, Heroku, Netlify, Azure | $200 - $5K |
| **Cloud/Infra** | S3 listing, EC2 metadata, Firebase, K8s, Docker API | $500 - $20K |
| **HTTP Smuggling** | CL.TE, TE.CL, TE.TE, H2.CL request tunneling | $5K - $30K |
| **Cache Poisoning** | Unkeyed headers, parameter cloaking, web cache deception | $1K - $10K |
| **MFA Bypass** | No rate limit, OTP reuse, response manipulation, race | $1K - $10K |
| **SAML/SSO** | XSW, comment injection, signature stripping, XXE | $2K - $20K |

</details>

<details>
<summary><b>10 Web3 Bug Classes</b> — click to expand</summary>
<br>

| Class | Frequency | Typical Payout |
|:---|:---|:---|
| **Accounting Desync** | 28% of Criticals | $50K - $2M |
| **Access Control** | 19% of Criticals | $50K - $2M |
| **Incomplete Code Path** | 17% of Criticals | $50K - $2M |
| **Off-By-One** | 22% of Highs | $10K - $100K |
| **Oracle Manipulation** | 12% of reports | $100K - $2M |
| **ERC4626 Attacks** | Moderate | $50K - $500K |
| **Reentrancy** | Classic | $10K - $500K |
| **Flash Loan** | Moderate | $100K - $2M |
| **Signature Replay** | Moderate | $10K - $200K |
| **Proxy/Upgrade** | Moderate | $50K - $2M |

</details>

<br>

---

<br>

## Tools & Architecture

<details>
<summary><b>Core Pipeline</b> — <code>tools/</code></summary>
<br>

| Tool | What It Does |
|:---|:---|
| `hunt.py` | Master orchestrator — chains recon, scan, report |
| `recon_engine.sh` | Subdomain enum + DNS + live hosts + URL crawl |
| `learn.py` | CVE + disclosure intel from NVD, GitHub Advisory, HackerOne |
| `intel_engine.py` | Memory-aware intel wrapper (learn.py + HackerOne MCP + memory) |
| `validate.py` | 4-gate validation — scope, impact, dedup, CVSS |
| `report_generator.py` | H1/Bugcrowd/Intigriti report output |
| `scope_checker.py` | Deterministic scope safety with anchored suffix matching |
| `cicd_scanner.sh` | GitHub Actions SAST — wraps [sisakulint](https://github.com/sisaku-security/sisakulint) remote scan (52 rules, 81.6% GHSA coverage) |
| `mindmap.py` | Prioritized attack mindmap generator |

</details>

<details>
<summary><b>Vulnerability Scanners</b> — <code>tools/</code></summary>
<br>

| Tool | Target |
|:---|:---|
| `h1_idor_scanner.py` | Object-level and field-level IDOR |
| `h1_mutation_idor.py` | GraphQL mutation IDOR |
| `h1_oauth_tester.py` | OAuth misconfigs (PKCE, state, redirect_uri) |
| `h1_race.py` | Race conditions (TOCTOU, limit overrun) |
| `zero_day_fuzzer.py` | Logic bugs, edge cases, access control |
| `cve_hunter.py` | Tech fingerprinting + known CVE matching |
| `vuln_scanner.sh` | Orchestrates nuclei + dalfox + sqlmap |
| `hai_probe.py` | AI chatbot IDOR, prompt injection |
| `hai_payload_builder.py` | Prompt injection payload generator |

</details>

<details>
<summary><b>MCP Integrations</b> — <code>mcp/</code></summary>
<br>

| Server | Tools Provided |
|:---|:---|
| **Caido** (`mcp/caido-mcp-server-main/`) | HTTP history search (HTTPQL), request replay/edit, scopes, filters, findings, intercept, fuzzing |
| **HackerOne** (`mcp/hackerone-mcp-server/`) | `search_disclosed_reports`, `get_program_stats`, `get_program_policy` |

Both MCPs are registered automatically by `install.sh` when the matching env vars are set (`CAIDO_PAT`, `H1_USERNAME`, `H1_API_TOKEN`). No credentials are ever bundled with the repo.

</details>

<details>
<summary><b>Caido Skill</b> — <code>skills/caido-mode/</code></summary>
<br>

Node.js CLI built on `@caido/sdk-client`. Gives Claude a second route into Caido alongside the MCP — same PAT, same backend, different invocation path.

| File | Purpose |
|:---|:---|
| `caido-client.ts` | CLI entry point — argument parsing + command dispatch |
| `lib/client.ts` | SDK client singleton + `SecretsTokenCache` (stores PAT/access token in `~/.claude/config/secrets.json`) |
| `lib/commands/*.ts` | Commands: requests, replay, findings, management, intercept, info |
| `ca.crt` | Caido root CA (for HTTPS interception validation) |

Deps are installed by `install.sh` in the destination dir (not shipped via `node_modules`).

</details>

<details>
<summary><b>Hunt Memory System</b> — <code>memory/</code></summary>
<br>

| Module | What It Does |
|:---|:---|
| `hunt_journal.py` | Append-only JSONL hunt log (concurrent-safe via `fcntl.flock`) |
| `pattern_db.py` | Cross-target pattern DB — matches by vuln class + tech stack |
| `audit_log.py` | Every outbound request logged + per-host rate limiter + circuit breaker |
| `schemas.py` | Schema validation for all entry types (versioned) |

</details>

<details>
<summary><b>Full Directory Structure</b> — click to expand</summary>
<br>

```
claude-bug-bounty/
├── skills/                     9 skill domains (SKILL.md files)
│   └── caido-mode/             Caido SDK CLI for Claude
├── commands/                   14 slash commands
├── agents/                     8 specialized AI agents
├── tools/                      21 Python/shell tools
├── memory/                     Persistent hunt memory system
├── mcp/                        MCP server integrations
│   ├── caido-mcp-server-main/  Caido web proxy
│   └── hackerone-mcp-server/   HackerOne public API
├── tests/                      129 tests
├── rules/                      Always-active hunting + reporting rules
├── hooks/                      Session start/stop hooks
├── docs/                       Payload arsenal + technique guides
├── web3/                       Smart contract skill chain
├── scripts/                    Shell wrappers
└── wordlists/                  5 wordlists
```

</details>

<br>

---

<br>

## Installation

### Prerequisites

```bash
# macOS
brew install go python3 node jq
brew install --cask caido

# Linux (Debian/Ubuntu)
sudo apt install golang python3 nodejs jq
# Caido desktop: download .deb from https://caido.io
```

> **Node.js v20+** is required for the `caido-mode` skill (**v24+ recommended**). `install_tools.sh` checks your version and prints an `nvm` upgrade hint if it's too old.

### Install

```bash
git clone https://github.com/shuvonsec/caido-bug-bounty.git
cd claude-bug-bounty
chmod +x install_tools.sh && ./install_tools.sh   # recon tools + Caido desktop/CLI + Node check
chmod +x install.sh        && ./install.sh        # skills + commands + MCPs
```

### API Keys (all user-supplied — never shipped in the repo)

<details>
<summary><b>Caido PAT</b> — required for Caido integration</summary>
<br>

1. Open Caido → **Dashboard → Developer → Personal Access Tokens**
2. Create a token (name it whatever, e.g. `claude-bug-bounty`)
3. Export it and re-run `install.sh` to register the MCP, then init the skill:

```bash
export CAIDO_PAT=caido_xxx
./install.sh   # registers the caido MCP with your PAT
npx tsx ~/.claude/skills/caido-mode/caido-client.ts setup "$CAIDO_PAT"
```

Stored locally at `~/.claude/config/secrets.json` by the skill. The MCP receives it via Claude Code env config.

</details>

<details>
<summary><b>HackerOne API token</b> — optional but recommended</summary>
<br>

Enables `/intel` disclosed-report lookups, program stats, and policy reads.

```bash
export H1_USERNAME=<your-h1-username>
export H1_API_TOKEN=<your-h1-api-token>   # h1.com → settings → API tokens
./install.sh
```

</details>

<details>
<summary><b>Chaos API</b> — required for full recon</summary>
<br>

1. Sign up at [chaos.projectdiscovery.io](https://chaos.projectdiscovery.io)
2. Export your key:

```bash
export CHAOS_API_KEY="your-key-here"
echo 'export CHAOS_API_KEY="your-key-here"' >> ~/.zshrc
```

</details>

<details>
<summary><b>Optional API keys</b> — better subdomain coverage</summary>
<br>

Configure in `~/.config/subfinder/config.yaml`:
- [VirusTotal](https://www.virustotal.com) — free
- [SecurityTrails](https://securitytrails.com) — free tier
- [Censys](https://censys.io) — free tier
- [Shodan](https://shodan.io) — paid

</details>

<br>

---

<br>

## The Golden Rules

These are always active. Non-negotiable.

```
 1. READ FULL SCOPE        verify every asset before the first request
 2. NO THEORETICAL BUGS    "Can attacker do this RIGHT NOW?" — if no, stop
 3. KILL WEAK FAST         Gate 0 is 30 seconds, saves hours
 4. NEVER OUT-OF-SCOPE     one request = potential ban
 5. 5-MINUTE RULE          nothing after 5 min = move on
 6. RECON ONLY AUTO        manual testing finds unique bugs
 7. IMPACT-FIRST           "worst thing if auth broken?" drives target selection
 8. SIBLING RULE           9 endpoints have auth? check the 10th
 9. A→B SIGNAL             confirming A means B exists nearby — hunt it
10. VALIDATE FIRST         7-Question Gate (15 min) before report (30 min)
```

<br>

---

<br>

## FAQ

<details>
<summary><b>Do I need Caido?</b></summary>
<br>

Strongly recommended. The `caido-mode` skill + Caido MCP is what lets Claude see your live proxy history, replay authenticated requests, and create findings without you copy-pasting cookies into curl. Without Caido, Claude falls back to issuing HTTP requests directly — it works, but you lose the "edit an already-authenticated request" workflow that makes IDOR/ATO testing 10x faster. Free tier is fine.

</details>

<details>
<summary><b>Where are my secrets stored?</b></summary>
<br>

- **`CAIDO_PAT`** — env var (you set) or `~/.claude/config/secrets.json` (written by `caido-client.ts setup`)
- **HackerOne creds** — env vars only; passed to the MCP via Claude Code's user-scoped config
- **Chaos / others** — your shell env (`.zshrc` / `.bashrc`)

Nothing sensitive is written into this repo. `install.sh` refuses to embed credentials — only reads them from env vars. If you've pulled an older version that bundled keyfiles, rotate those tokens and `git rm --cached` the files.

</details>

<details>
<summary><b>Can I run this without Claude Code?</b></summary>
<br>

Yes — every Python tool under `tools/` runs standalone. You lose the agent orchestration, memory-informed ranking, and slash commands, but you keep the scanners, validators, and report generator.

</details>

<br>

---

<br>

## The Trilogy

| Repo | Purpose |
|:---|:---|
| **[claude-bug-bounty](https://github.com/shuvonsec/claude-bug-bounty)** | Full hunting pipeline — recon to report, with Caido integration |
| **[web3-bug-bounty-hunting-ai-skills](https://github.com/shuvonsec/web3-bug-bounty-hunting-ai-skills)** | Smart contract security — 10 bug classes, Foundry PoCs |
| **[public-skills-builder](https://github.com/shuvonsec/public-skills-builder)** | Ingest 500+ writeups into Claude skill files |

<br>

---

<br>

## Contributing

PRs welcome. Best contributions:

- New vulnerability scanners or detection modules
- Payload additions to `skills/security-arsenal/SKILL.md`
- New agent definitions for specific platforms
- Real-world methodology improvements (with evidence from paid reports)
- Additional Caido HTTPQL filter presets / workflow scripts
- Platform support (YesWeHack, Synack, HackenProof)

```bash
git checkout -b feature/your-contribution
git commit -m "Add: short description"
git push origin feature/your-contribution
```

<br>

---

<br>

<div align="center">

### Connect

[GitHub](https://github.com/cfazuero1) &nbsp;&nbsp;|&nbsp;&nbsp; [LinkedIn](https://www.linkedin.com/in/christian-azuero/) &nbsp;&nbsp;|&nbsp;&nbsp; [Email](mailto:christian.azuero@gmail.com)

<br>

---

**For authorized security testing only.** Only test targets within an approved bug bounty scope.<br>
Never test systems without explicit permission. Follow responsible disclosure practices.

---

<br>


**Built by bug hunters, for bug hunters.**

If this helped you find a bug, leave a like in linkedin.

</div>
