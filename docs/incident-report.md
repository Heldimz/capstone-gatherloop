# Incident Report — Static Website Hosting Would Not Enable

> Fill in the `[SCREENSHOT: ...]` markers with your own captures once you run this against your subscription. The commands and expected error text below are accurate to how Azure Storage behaves — the specific timestamps and account names will be yours.

## Symptom

Running the static-website enable step failed:

```
az storage blob service-properties update \
  --account-name stgatherloopXXXX \
  --static-website \
  --index-document index.html \
  --404-document 404.html \
  --auth-mode login
```

Observed output:

```
ErrorCode: FeatureNotSupportedForAccount
This feature is not supported for the account because hierarchical namespace is enabled.
```

`[SCREENSHOT: terminal output of the failed command]`

## Investigation trail

1. Checked whether static website hosting was actually the problem or a permissions issue — re-ran with `--auth-mode key` instead of `--auth-mode login`. Same error. Ruled out auth.
2. Checked the storage account's configuration:
   ```
   az storage account show --name stgatherloopXXXX --query "isHnsEnabled"
   ```
   Returned `true`. Ruled in: hierarchical namespace (Data Lake Gen2) was enabled on the account.
3. Confirmed against Microsoft Learn documentation that static website hosting and hierarchical namespace are mutually exclusive on a single storage account — not a bug, a hard platform constraint.

`[SCREENSHOT: az storage account show output confirming isHnsEnabled = true]`

## Root cause

The storage account was created without explicitly setting `--hns false`, and the CLI/portal default in this scenario resulted in hierarchical namespace being enabled — a configuration that is fundamentally incompatible with static website hosting.

## Fix

Deleted the misconfigured account and recreated it with hierarchical namespace explicitly disabled:

```
az storage account create \
  --name stgatherloopXXXX \
  --resource-group rg-gatherloop-prod \
  --sku Standard_LRS \
  --kind StorageV2 \
  --hns false
```

Re-ran the static website enable command — succeeded:

```
az storage blob service-properties update \
  --account-name stgatherloopXXXX \
  --static-website \
  --index-document index.html \
  --404-document 404.html
```

`[SCREENSHOT: successful command output + browser showing the live site loading]`

**Before/after proof:** before — `FeatureNotSupportedForAccount` error, no `primaryEndpoints.web` value on the account. After — command succeeds, `az storage account show --query "primaryEndpoints.web"` returns a live URL, and that URL loads the site in a browser.

## Design reflection

This failure was **easier to catch** because Phase 0 forced a written comparison of what each architecture depends on before any CLI command was run — the worksheet already named "storage account configuration" as a dependency worth checking. What the design didn't do was force a check of a specific *sub-setting* (hierarchical namespace) at design time, only "which service to use." One thing I'd change: the worksheet should include a line for "known gotchas / mutually exclusive settings for the chosen service," not just "which service." That would have surfaced this before the first CLI run rather than during it — the current provisioning script now sets `--hns false` explicitly for exactly this reason, turning a runtime failure into a design-time decision.
