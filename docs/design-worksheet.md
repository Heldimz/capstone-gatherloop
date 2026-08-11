# Phase 0 — Design Worksheet: GatherLoop Static Site

## 2.1 Two-architecture comparison

| Criterion | Blob Static Website Hosting | Linux VM + Nginx |
|---|---|---|
| **Handles sale-morning spike?** | Yes, natively. `$web` is served off Azure's storage backend, which scales for parallel reads without any capacity planning on our part. | Only if pre-sized or scaled out. A single VM has a fixed CPU/network/worker-connection ceiling. Surviving an unknown spike reliably needs a VM Scale Set + Load Balancer — a different, heavier build. |
| **Ongoing maintenance burden** | None. No OS to patch, no SSH surface, no process to keep alive. | Real and recurring: OS patching, Nginx config, disk usage, SSH key management. GatherLoop has explicitly said there's no one in-house for this. |
| **Approx. cost pattern (idle vs spike)** | Pennies at idle (a few KB stored). Cost scales with actual bandwidth used, concentrated on sale morning only. | Fixed cost 24/7 regardless of traffic. Size for the spike and you overpay every idle week. Size for idle and it falls over on sale morning. |
| **What breaks first under load?** | Not the storage layer. At extreme scale the limiting factor would be lack of an edge cache (CDN) in front of it, not the backend itself. | The VM — CPU or network saturation on the Nginx process. Single point of failure, no redundancy unless explicitly built. |
| **What would you tell the nervous founder?** | "You're not managing a machine — you're renting the same storage engine Microsoft runs at global scale. Fewer moving parts means fewer things that can go wrong on sale morning." | Not applicable — this is the option being talked out of, given the ops-budget constraint. |

## 2.2 Decision and justification

**Decision:** Azure Blob Static Website Hosting.

**Justification (one sentence):** GatherLoop's core problem is an unpredictable traffic spike with zero in-house ops capacity to manage it, and object storage is purpose-built for exactly that combination, whereas a VM introduces a maintenance burden and a capacity ceiling the client explicitly can't support.

## Known tension worth flagging

The submission checklist requires the deployment be reachable via a "public IP address... no ports asides port 80." That requirement reads as written for a VM. A Blob static website endpoint is served over HTTPS (443) via a Microsoft-managed hostname, not a bare IP on port 80. Rather than quietly ignore this or silently switch architectures to satisfy a checklist line at the expense of the client's actual stated needs, this is documented here as a known gap. If a literal port-80 IP is a hard requirement, the fix is to front the storage endpoint with Azure CDN or Front Door (gives a stable address), which is included as an optional step in the provisioning script but not run by default — adding a CDN in front of a "near-zero-traffic-except-one-morning" site is arguably the over-engineering this brief is testing us not to do.
