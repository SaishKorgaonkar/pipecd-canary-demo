# Presentation script & demo runbook (10-minute slot)

**Format:** play `PipeCD_TheoryIA_Demo_Video.mp4` (9:53, 1080p, no audio) by screen-sharing in Meet,
and voice it over live using the timestamps below. The video goes from slides to the live demo, back to
slides while the first deployment runs, then shows the live app, the faulty release and the fix, and ends
on the results. Parts marked **2×** are sped-up waits, labelled on screen.

Rehearse with `PipeCD_TheoryIA_Demo_Video.srt` (same folder). VLC/IINA show it automatically and display
who speaks when. Don't load the subtitles when you share the video in the real session.

Speaking time: Saish ≈ 3:17 · Shreejay ≈ 3:45 · Chaitanya ≈ 2:51

---

## Part A: Voiceover script (synced to the video)

| Time | Speaker | On screen |
|---|---|---|
| 0:00–0:15 | Saish | Slide 1: Title |
| 0:15–1:15 | Saish | Slide 2: The problem & the idea |
| 1:15–1:32 | Saish | Demo: GitOps repository |
| 1:32–1:50 | Saish | Demo: register the app in PipeCD |
| 1:50–2:20 | Saish | Demo: first deployment starts |
| 2:20–3:15 | Shreejay | Slide 3: PipeCD in a nutshell |
| 3:15–4:20 | Shreejay | Slide 4: How it works: our pipeline |
| 4:20–4:45 | Shreejay | Demo: live application v1 |
| 4:45–5:12 | Shreejay | Demo: release v2 (faulty); 2× while piped picks it up |
| 5:12–6:05 | Shreejay | Demo: v2 canary live, ANALYSIS running |
| 6:05–6:27 | Chaitanya | Demo: ANALYSIS failed → automatic ROLLBACK |
| 6:27–7:12 | Chaitanya | Demo: release v3 (fix); 2× while piped picks it up |
| 7:12–7:53 | Chaitanya | Demo: canary 25%, ANALYSIS (2× in places) |
| 7:53–8:38 | Chaitanya | Demo: canary 50%, second ANALYSIS (2× in places) |
| 8:38–8:56 | Chaitanya | Demo: promoted to 100%, all stages green |
| 8:56–9:41 | Saish | Slide 5: Results & takeaways |
| 9:41–9:53 | Saish | Slide 6: Thank you |

### 0:00–0:15 · Saish: Slide 1: Title
> Good morning. We're Saish, Shreejay and Chaitanya. Our topic is GitOps-based progressive delivery and automated rollback using PipeCD, a CNCF continuous-delivery tool.

### 0:15–1:15 · Saish: Slide 2: The problem & the idea
> In a normal deployment the new version replaces the old one for everyone at once. If it has a bug, every user sees it. Health checks don't save you either: a pod can be "Ready" and still return errors. So users notice first, and someone rolls back by hand.
>
> We combine two ideas to fix this. GitOps: Git is the single source of truth, so a release is just a commit, and an agent in the cluster applies it. And canary releases: the new version gets a small slice of real traffic, an automated check runs, and the slice grows only if the check passes. Otherwise it rolls back automatically. Let's see it.

### 1:15–1:32 · Saish: Demo: GitOps repository
> This is our GitOps repository. The Kubernetes Deployment says which image runs: demo-web v1. Next to it is app.pipecd.yaml, the deployment pipeline itself, also written as code.

### 1:32–1:50 · Saish: Demo: register the app in PipeCD
> In the PipeCD console we add the application. piped, PipeCD's agent, has already found it in the repo. We pick the agent, the Kubernetes cluster and the app, and save.

### 1:50–2:20 · Saish: Demo: first deployment starts
> PipeCD immediately plans the first deployment: make the cluster match Git. Notice the live application panel on the right still says no running pods. While that deploys, Shreejay will explain what's happening behind the scenes.

### 2:20–3:15 · Shreejay: Slide 3: PipeCD in a nutshell
> PipeCD has two parts. The Control Plane is the web console and API you just saw. It stores history and coordinates, but it never touches the cluster itself.
>
> piped is a small agent that runs next to the cluster. It watches Git, notices new commits, plans the deployment and executes every stage. It only makes outbound connections, so cluster credentials never leave the cluster. PipeCD is a CNCF sandbox project created by CyberAgent, and the same model works for Terraform, ECS, Lambda and Cloud Run.

### 3:15–4:20 · Shreejay: Slide 4: How it works: our pipeline
> This is our pipeline. When the image changes, PipeCD first starts the new version as a canary on 25% of the pods, so about one in five requests reaches it. Then an ANALYSIS stage calls the canary every 10 seconds and expects HTTP 200. More than one failure fails the stage. If it passes, the canary grows to 50%, is analysed again, and is then promoted to 100%.
>
> autoRollback is on, so if any stage fails PipeCD undoes everything by itself. We built three versions: v1 is stable, v2 is deliberately broken (it returns HTTP 500 but its health check still passes), and v3 is the fix.

### 4:20–4:45 · Shreejay: Demo: live application v1
> Back to the demo. The first deployment succeeded and the app is Synced with Git. On the right is the live application: version 1. Our traffic generator sends 20 requests a second, and 100% are answered by v1 with zero errors.

### 4:45–5:12 · Shreejay: Demo: release v2 (faulty); 2× while piped picks it up
> Now the faulty release. A release is just one line in Git: the image tag changes from v1 to v2, we commit and push. Nobody runs kubectl. piped polls the repository and picks up the new commit.

### 5:12–6:05 · Shreejay: Demo: v2 canary live, ANALYSIS running
> PipeCD says it will sync progressively because the image changed. The canary is up. Look at the right: about a quarter of the requests now hit v2 and fail with HTTP 500, shown in red. The ANALYSIS stage is probing the canary, and in the log you can see it getting unexpected status code 500.

### 6:05–6:27 · Chaitanya: Demo: ANALYSIS failed → automatic ROLLBACK
> And there it is: ANALYSIS failed, the rest of the pipeline was skipped, and PipeCD ran ROLLBACK by itself. It deleted the canary and kept v1. On the right, traffic is back to 100% v1 with zero errors. No human touched the cluster.

### 6:27–7:12 · Chaitanya: Demo: release v3 (fix); 2× while piped picks it up
> Now the developer pushes the fix, v3, the same way: one line in Git, commit, push. PipeCD picks it up and starts the same pipeline.

### 7:12–7:53 · Chaitanya: Demo: canary 25%, ANALYSIS (2× in places)
> The v3 canary is live on 25% of the pods. Green on the right is v3, roughly a fifth of the traffic, and every request succeeds. The analysis gets HTTP 200 each time, so this time it passes.

### 7:53–8:38 · Chaitanya: Demo: canary 50%, second ANALYSIS (2× in places)
> PipeCD now grows the canary to 50%, and v3's share rises to about a third of live traffic. This is the progressive part: the new version earns more traffic only after each check passes.

### 8:38–8:56 · Chaitanya: Demo: promoted to 100%, all stages green
> Second analysis passed, so v3 is promoted to the primary and the canary is cleaned up. All six stages are green, 100% of traffic is on v3, and there were zero errors during the rollout.

### 8:56–9:41 · Saish: Slide 5: Results & takeaways
> To sum up, from our measured runs: the broken version was exposed for only about half a minute, to about a fifth of requests, and the rollback took about 2 seconds with no human involved. The fix rolled out with zero errors.
>
> Our takeaways: health checks don't prove correctness, and only the analysis caught v2. Releases and rollbacks happened without anyone running kubectl, and Git gives a full audit trail. Next we'd add Prometheus metrics, Istio traffic weights and PipeCD's Event Watcher to connect it to CI.

### 9:41–9:53 · Saish: Slide 6: Thank you
> Everything we showed is in our public repository on screen. Thank you.

---

## Part B: Demo runbook

### B1. One-time setup (on the demo laptop, ~15 min, do it a day before)
Prereqs: Docker Desktop running (give it ≥ 6 GB RAM), `kubectl`, `minikube`, `git`, and push
access to this repo.

```bash
git clone https://github.com/SaishKorgaonkar/pipecd-canary-demo.git && cd pipecd-canary-demo
./scripts/00-cluster.sh          # minikube + builds demo-web:v1/v2/v3 into it
./scripts/01-install-pipecd.sh   # PipeCD control plane (waits until ready)
kubectl port-forward -n pipecd svc/pipecd 8080      # leave running (Terminal 1)
```
1. Open <http://localhost:8080?project=quickstart> and log in with `hello-pipecd` / `hello-pipecd`.
2. **Settings → Piped → + ADD**, name `dev`, then Save. Copy the **Piped Id** and the **Base64 Encoded Piped Key**.
3. `./scripts/02-install-piped.sh <PIPED_ID> <BASE64_KEY>`
4. **Applications → + ADD → PIPED V0 ADD FROM SUGGESTIONS**: piped `dev`, provider `kubernetes-default`, app `web`. Save, then confirm.
5. Wait for the first deployment to show **SUCCESS** (Deployments page).

> Saish's laptop already has all of this set up (minikube profile `pipecd-demo`).

### B2. Before you present (~10 min before)
```bash
minikube start -p pipecd-demo              # only if the laptop was restarted
kubectl get pods -n pipecd                 # all Running
kubectl port-forward -n pipecd svc/pipecd 8080      # Terminal 1, leave running
grep image: manifests/web/deployment.yaml  # must say demo-web:v1
```
If it doesn't say v1: `./scripts/release.sh v1`, then wait until that deployment is **SUCCESS**
(~2.5 min). **Don't present while a deployment is still running.**

Check: `kubectl get deploy -n demo -o wide` shows `web 4/4 demo-web:v1` and **no** `web-canary`.

### B3. Live presenting instead of the video: screen layout
Use two fullscreen spaces and switch between them (Ctrl+← / Ctrl+→ on a Mac):
- **Space 1:** the slides (`PipeCD_TheoryIA_Demo_8slides.pptx`), in slideshow mode.
- **Space 2:** the demo stage. Run `python3 stage/server.py`, open <http://localhost:7700> in Chrome and make it fullscreen
  (log in to the console at localhost:8080 first). It shows the PipeCD console, the live app, live traffic (20 req/s)
  and a terminal panel in one screen.
- Keep a terminal handy (hidden) for `./scripts/release.sh v2` / `v3`. Its output also appears in the stage's terminal panel.

### B4. Live sequence (same order as the video)
| # | When | Action | What the audience sees |
|---|---|---|---|
| 1 | after slide 2 | Space 2: show the repo and register `web` in PipeCD (Applications → + ADD) | first deployment planned |
| 2 | slides 3–4 | Space 1: explain PipeCD and the pipeline (~2 min) | first deploy completes meanwhile |
| 3 | after slide 4 | Space 2: open the deployment, then Applications | SUCCESS, live app **v1**, 100% v1 |
| 4 | | `./scripts/release.sh v2`, then open the new deployment | canary → `v2 ERR` in red → ANALYSIS ✖ → ROLLBACK ✔ (~85 s after the push) |
| 5 | | `./scripts/release.sh v3`, then open the new deployment | 25% → 50% → 100% v3, all ✔ (~3 min) |
| 6 | | Space 1: slides 5–6 | results, thank you |

To start from scratch, as the video does (app not yet registered): delete the app in PipeCD
(Applications → ⋮ → Delete), run `kubectl delete ns demo`, then `./scripts/release.sh v1`.

### B5. If something goes wrong
| Problem | Fix |
|---|---|
| No new deployment appears after a push | Wait 20 s and click REFRESH. Check `git log origin/main -1`. Check logs: `kubectl logs -n pipecd deploy/piped --tail=20` |
| Console won't load | The port-forward died. Re-run `kubectl port-forward -n pipecd svc/pipecd 8080` |
| `traffic.sh` says the pod already exists | Run `kubectl -n demo delete pod traffic`, then start it again |
| `git push` rejected | `git pull --rebase && git push` |
| Something breaks live | Play the recorded video, or use the two backup slides at the end of the deck |

### B6. After the demo (to repeat it)
`./scripts/release.sh v1`, then wait for SUCCESS. That's the reset.
To shut down: `minikube stop -p pipecd-demo`.
