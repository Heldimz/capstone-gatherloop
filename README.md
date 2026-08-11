# GatherLoop — Static Site Deployment

Capstone Project — Group 3. A single-page conference promo site, deployed on Azure Blob Static Website Hosting, with GitHub Actions auto-redeploy on push to `main`.

## Note to the founder

You asked whether "some storage thing" counts as a real website compared to a real server. It does — you're not getting a lesser version of a website, you're getting a specialized one. Instead of running a whole computer that has to be turned on, patched, and watched 24 hours a day just so it's ready in case tickets go on sale, your site lives on Microsoft's storage infrastructure, the same system built to hold and serve enormous amounts of data reliably at any scale. On a quiet week it costs next to nothing, and on sale morning it doesn't need to be resized or rescued — it just handles it, because that's what it's built for. No server means no one has to babysit a server.

## Architecture

Azure Blob Static Website Hosting. Full reasoning and the two-architecture comparison are in [`docs/design-worksheet.md`](docs/design-worksheet.md).

## Repo structure

```
GatherLoop/
├── site/                    # static site content
│   ├── index.html
│   ├── style.css
│   └── 404.html
├── scripts/
│   └── provision.sh         # CLI-only infrastructure provisioning
├── .github/workflows/
│   └── deploy.yml           # auto-redeploy on push to main
├── docs/
│   ├── design-worksheet.md  # Phase 0 comparison + decision
│   └── incident-report.md   # incident encountered during build
└── README.md
```

## One-time setup

### 1. Provision the infrastructure

```bash
cd scripts
chmod +x provision.sh
./provision.sh
```

This creates the resource group, storage account (with hierarchical namespace explicitly disabled — see the incident report for why that matters), enables static website hosting, and does the first upload. It prints the live site URL at the end.

### 2. Wire up GitHub Actions

Create a service principal scoped to the resource group so Actions can deploy without a personal login:

```bash
az ad sp create-for-rbac \
  --name "gatherloop-deploy" \
  --role contributor \
  --scopes /subscriptions/<your-subscription-id>/resourceGroups/rg-gatherloop-prod \
  --sdk-auth
```

Copy the full JSON output into a GitHub repo secret named `AZURE_CREDENTIALS`.
Add a second secret, `AZURE_STORAGE_ACCOUNT`, with the storage account name printed by `provision.sh`.

From here, every push to `main` that touches `site/` redeploys automatically.

## Live site

`[Paste your primaryEndpoints.web URL here after running provision.sh]`

## Deliverables checklist

- [x] Site code (`site/`)
- [x] CLI provisioning script (`scripts/provision.sh`)
- [x] GitHub Actions workflow (`.github/workflows/deploy.yml`)
- [x] Completed two-architecture comparison worksheet (`docs/design-worksheet.md`)
- [ ] Screenshots of the live site and successful Actions run — add after your first real deploy
- [x] Incident report (`docs/incident-report.md`)
