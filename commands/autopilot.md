---
description: Run autonomous hunt loop on a target — scope check → recon → rank surface → hunt → validate → report with configurable checkpoints. Usage: /autopilot target.com [--paranoid|--normal|--yolo]
---

# /autopilot

Autonomous hunt loop with deterministic scope safety and configurable checkpoints.

## Usage

```
/autopilot target.com                    # default: --paranoid mode
/autopilot target.com --normal           # batch checkpoint after validation
/autopilot target.com --yolo             # minimal checkpoints (still requires report approval)
```

## What This Does

Runs the full hunt cycle without stopping for approval at each step:

```
1. SCOPE     Load and confirm program scope
2. RECON     Run recon (or use cached if < 7 days old)
3. RANK      Prioritize attack surface (recon-ranker agent)
4. HUNT      Test P1 endpoints systematically
5. VALIDATE  7-Question Gate on findings
6. REPORT    Draft reports for validated findings
7. CHECKPOINT  Present to human for review
```

## Caido Integration

Autopilot uses caido-client.ts for all active testing when Caido is running. Active project: **deriv-hunt**.

```bash
CAIDO="npx tsx ~/.claude/skills/caido-mode/caido-client.ts"
```

### Session Start (always)
```bash
# 1. Verify Caido is up
$CAIDO health

# 2. Select deriv-hunt project
$CAIDO select-project 23905d32-e1e5-4ac5-8da0-11ea14f686eb

# 3. Create scope for target (captures all in-scope traffic)
$CAIDO create-scope "$TARGET" --allow "*.$TARGET"

# 4. Confirm passive workflows are running (auto-flag on all traffic)
#    p:4 SecretSniffer, p:12 Leakz, p:6 Redirect To Parameter Value,
#    p:8 OWASP Top 25, p:21 GAP Sus Params, p:1 Url In Parameter,
#    p:22/23 FindSSO/EvalSSO, p:27 Cookie Reflection, p:28 Content-Length Mismatch,
#    p:14 JSON Wrong Content-Type, p:16 HTTP Method Checker, p:18 Hostname in Response

# 5. Create filter presets for this hunt session
$CAIDO create-filter "API Endpoints" --query 'req.path.cont:"/api/"'
$CAIDO create-filter "ID Parameters" --query 'req.path.regex:"/[0-9]+"'
$CAIDO create-filter "Auth Flows" --query 'req.path.regex:"/(login|auth|oauth|token|callback)"'
$CAIDO create-filter "Errors 5xx" --query 'resp.code.gte:500'
$CAIDO create-filter "403 Responses" --query 'resp.code.eq:403'
```

### RECON Step
```bash
# After manual browsing, pull passive workflow hits
$CAIDO search 'source:"workflow"' --limit 50
$CAIDO findings --limit 20

# Triage attack surface from captured traffic
$CAIDO search 'req.path.cont:"/api/" AND resp.code.eq:200' --limit 100
$CAIDO search 'req.path.regex:"/[0-9]+" AND resp.code.eq:200' --limit 50
$CAIDO search 'req.path.cont:"graphql"' --limit 20
$CAIDO search 'resp.code.gte:500' --limit 20

# Plugins to activate:
# JS Analyzer + jxscout — JS bundle endpoint/secret extraction
# ParamFinder — hidden param discovery on API endpoints
# Scanner — passive vuln detection
# RetireJS Scanner — outdated JS libs
# GraphQL Analyzer — if GraphQL detected (use p:15 Introspection workflow)
```

### HUNT Step
```bash
# IDOR testing — preserve auth, modify only the ID
$CAIDO edit <request-id> --path /api/user/VICTIM_ID
$CAIDO edit <request-id> --replace "OWN_ID:::VICTIM_ID"

# Auth bypass — swap tokens between accounts
$CAIDO edit <request-id> --set-header "Authorization: Bearer VICTIM_TOKEN"
# Plugins: Autorize, AuthMatrix, Authify, Authswap, JWT Analyzer

# 403 bypass — on every 403 response
$CAIDO search 'resp.code.eq:403' --limit 20
# Plugin: 403Bypasser

# CORS check — on API endpoints
$CAIDO edit <request-id> --set-header "Origin: https://evil.com"
# Workflow: p:25 CORS Checker (active)

# Host header injection — on password reset flows
$CAIDO edit <request-id> --set-header "X-Forwarded-Host: evil.com"
# Plugin: Host Header Injector

# SSRF — on URL-accepting params
# Plugin: QuickSSRF

# WAF bypass — use convert workflow p:9 nowafpls in Automate
```

### VALIDATE Step
```bash
# Pull exact request/response for the finding
$CAIDO get <request-id>
$CAIDO get-response <request-id> --compact

# Check passive workflow corroboration on same host
$CAIDO search 'source:"workflow" AND req.host.eq:"target.com"' --limit 20

# Register finding in Caido
$CAIDO create-finding <request-id> \
  --title "[Bug Class] in [endpoint]" \
  --description "Confirmed: [what attacker can do]"
```

### REPORT Step
```bash
# Export curl PoC — paste directly into Steps to Reproduce
$CAIDO export-curl <request-id>

# Create named replay session for triager replication
$CAIDO create-session <request-id>
$CAIDO rename-session <session-id> "poc-[bug-class]-[endpoint]"

# Pull all findings logged this session
$CAIDO findings --limit 50
```

### Fallback (if Caido drops)
```bash
$CAIDO health  # check first
# --paranoid/--normal: ask user to continue in degraded mode (curl)
# --yolo: auto-fallback to curl after 10 seconds
```

## Safety Guarantees

- **Every URL** is checked against the scope allowlist before any request
- **Every request** is logged to `hunt-memory/audit.jsonl`
- **Reports are NEVER auto-submitted** — always requires explicit approval
- **PUT/DELETE/PATCH** require human approval in --yolo mode (safe methods only)
- **Circuit breaker** stops hammering if 5 consecutive 403/429/timeout on same host
- **Rate limited** at 1 req/sec (testing) and 10 req/sec (recon)

## Checkpoint Modes

| Mode | When it stops | Best for |
|---|---|---|
| `--paranoid` | Every finding + partial signal | New targets, learning the surface |
| `--normal` | After validation batch | Systematic coverage |
| `--yolo` | After full surface exhausted | Familiar targets, experienced hunters |

## After Autopilot

- Run `/remember` to log successful patterns to hunt memory
- Run `/resume target.com` next time to pick up where you left off
- Check `hunt-memory/audit.jsonl` for a full request log
