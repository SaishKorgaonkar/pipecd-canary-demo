# GitOps progressive delivery and automated rollback with PipeCD

Theory IA demo, KJ Somaiya School of Engineering.
**Team:** Saish Korgaonkar (16010123294), Shreejay Kurhade (16010123320), Chaitanya Dhamdhere (16010123101)

A containerised web app is deployed to Kubernetes (Minikube) by **PipeCD**, using this
repository as the GitOps source of truth. A new version is released with a **canary**:
traffic shifts to it step by step and is checked by automated **analysis**. A broken
release (v2) is caught, and PipeCD **rolls it back automatically**. A fixed release (v3)
then rolls out all the way.

```
 developer ──git push──▶ GitHub (this repo) ◀──polls every 10s── piped (agent, in cluster)
                                                                   │  plans + executes
 PipeCD Control Plane (web UI, API) ◀──reports status/logs─────────┤
                                                                   ▼
                                                     Kubernetes (Minikube), namespace demo
                                                     web (primary, 4 pods) + web-canary
```

## What's in the repo

| Path | Purpose |
|---|---|
| `app/` | Demo web app (Python, stdlib only) + Dockerfile. v1 is blue and healthy, **v2 is red and broken (`/` returns HTTP 500)**, v3 is green and fixed. `/healthz` is always 200, so Kubernetes alone can't tell v2 is broken; only PipeCD's analysis catches it. |
| `manifests/web/deployment.yaml` | The Deployment. **Changing `image:` here is how you release.** |
| `manifests/web/service.yaml` | Service that selects primary *and* canary pods, so traffic splits by pod count. |
| `manifests/web/app.pipecd.yaml` | The PipeCD pipeline (below). |
| `scripts/` | Cluster setup, PipeCD install, live traffic monitor, release helper. |

### The pipeline (`app.pipecd.yaml`)

| # | Stage | What happens |
|---|---|---|
| 1 | `K8S_CANARY_ROLLOUT` 25% | 1 canary pod next to 4 primary pods, so about 20% of live traffic hits the new version |
| 2 | `ANALYSIS` (60s) | piped sends `GET http://web-canary.demo:8080/` every 10s. More than 1 non-200 response fails the stage. |
| 3 | `K8S_CANARY_ROLLOUT` 50% | 2 canary pods, about 33% of traffic |
| 4 | `ANALYSIS` (60s) | same check at the higher traffic share |
| 5 | `K8S_PRIMARY_ROLLOUT` | the new version replaces the primary (100%) |
| 6 | `K8S_CANARY_CLEAN` | canary pods and service removed |
| ✖ | `ROLLBACK` (automatic) | runs if any stage fails (`planner.autoRollback: true`). The canary is deleted and the primary is re-applied from the last good commit. |

## Setup (one time, about 10 min)

Prereqs: Docker Desktop (6 GB+ RAM), `kubectl`, `minikube` (`brew install minikube`), `git`.

```bash
./scripts/00-cluster.sh          # start minikube + build demo-web:v1/v2/v3 into it
./scripts/01-install-pipecd.sh   # PipeCD control plane (quickstart mode)
kubectl port-forward -n pipecd svc/pipecd 8080   # keep running in its own terminal
```

1. Open <http://localhost:8080?project=quickstart> and log in with `hello-pipecd` / `hello-pipecd`.
2. **Settings → Piped → + ADD**, name `dev`, then Save. Copy the *Piped Id* and the *Base64 Encoded Piped Key*.
3. `./scripts/02-install-piped.sh <PIPED_ID> <BASE64_KEY>`
4. **Applications → + ADD → PIPED V0 ADD FROM SUGGESTIONS**: piped `dev`, provider `kubernetes-default`, app `web`. Save, then confirm.
   PipeCD does the first deploy (QUICK_SYNC) of whatever tag is in Git.

> Make sure `manifests/web/deployment.yaml` says `demo-web:v1` before step 4
> (`./scripts/release.sh v1` if not).

## Demo script (for the video, about 8 min)

Use three windows: **(A)** PipeCD console on the Deployments page, **(B)** a terminal running
`./scripts/traffic.sh`, **(C)** a terminal for git.

| Time | Do | Say / show |
|---|---|---|
| 0:00 | Show repo on GitHub + `app.pipecd.yaml` | "Git is the source of truth. The pipeline is declared in Git too." |
| 1:00 | (B) `./scripts/traffic.sh` | 20 requests/sec, all `v1 OK x20` |
| 1:30 | (C) `./scripts/release.sh v2` | "Releasing v2 is just a commit that changes the image tag." |
| 1:45 | (A) new deployment appears, open it | Planner: *"Sync progressively because of updating image demo-web from v1 to v2"* |
| 2:00 | (B) | `v1 OK x16  v2 ERR x4`: the canary takes about 20% of traffic and fails |
| 2:00 | Optional: `kubectl -n demo port-forward deploy/web-canary 9090:8080`, open localhost:9090 | the 500 error page |
| 2:30 | (A) ANALYSIS turns red, ROLLBACK turns green | open the ANALYSIS log: `unexpected status code 500 … failure number exceeded the failure limit` |
| 3:00 | (B) | back to `v1 OK x20`. Users are protected, with no human involved. `kubectl get deploy -n demo` shows primary still on v1 |
| 3:30 | (C) `./scripts/release.sh v3` | "The developer pushes the fix." |
| 4:00 | (B) | `v1 OK x16  v3 OK x4`, then about 1 in 3 at 50% |
| 6:30 | (A) all 6 stages green | (B) `v3 OK x20`. Optional: port-forward `svc/web` to show the green page |

Each ANALYSIS lasts 60s, so a full successful rollout takes about 3 minutes. The failed one rolls back in about 25 seconds.

## Verified run (2026-11-15, Minikube v1.39 / Kubernetes v1.37, PipeCD v0.56 quickstart)

See `docs/screenshots/` and `docs/traffic-sample.log`.

* v2: `K8S_CANARY_ROLLOUT ✔ → ANALYSIS ✖ (HTTP 500 ×2) → ROLLBACK ✔`. The canary was live for about 30s at about 20% of traffic.
* v3: all six stages ✔. Traffic went 20% → 33% → 100% v3 with zero errors.

## Notes / gotchas

* Manifests set `metadata.namespace: demo` explicitly. Without it, PipeCD's generated
  `web-canary` Service went to `default`.
* The Service is `ClusterIP`. A `nodePort` gets copied into the generated canary Service and is rejected.
* The pinned quickstart is a master commit, because the `v0.58.0` tag's quickstart references a
  MinIO image that's been removed from Docker Hub.
* This demo keeps app source and manifests in one repo for simplicity. In production these are
  usually two repos (source repo + GitOps/manifest repo), with PipeCD's Event Watcher bumping the tag.

## Cleanup

```bash
kubectl delete ns demo pipecd
minikube delete -p pipecd-demo
```
