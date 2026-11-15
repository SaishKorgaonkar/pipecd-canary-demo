# Presentation script & demo runbook (10-minute slot)

Deck: `PipeCD_TheoryIA_Demo_8slides.pptx`. Slides and the live demo run side by side.
The white **▶** text in each slide's red footer tells you when to switch screens.

**Roles**
- **Saish** runs the laptop the whole time (types commands, switches windows) and presents slides 1–2.
- **Shreejay** presents slides 3–4 and narrates the faulty release.
- **Chaitanya** presents slides 5–8 and narrates the fixed release.

---

## Part A: Speaking script

### Saish: Slide 1, Title (~20 s)
> Good morning. We're Saish, Shreejay and Chaitanya. Our topic is GitOps-based progressive delivery
> and automated rollback using PipeCD, a CNCF continuous-delivery tool. In the next few minutes
> we'll release a broken version of an app and let PipeCD catch it and roll it back by itself.
> Then we'll release the fix and watch it roll out safely.

### Saish: Slide 2, The problem & the idea (~60 s)
> In a normal deployment the new version replaces the old one for everyone at once. If it has a bug,
> 100% of users see it. Health checks don't save you either. A pod can be "Ready" and still return
> errors. So users notice first, and someone rolls back by hand under pressure.
>
> We combine two ideas to fix this. First, **GitOps**: Git is the single source of truth, so a release
> is just a commit, and an agent inside the cluster applies it. Second, **canary releases**: the new
> version gets a small slice of real traffic, an automated check runs, and the slice only grows if
> the check passes. If it fails, the release is rolled back automatically.

**▶ DEMO (Saish switches screen)**
> Here's our GitOps repository on GitHub. The Kubernetes YAML and the pipeline file live here.
> In the PipeCD console our app `web` is running **v1**. This terminal sends 20 requests a second
> to the app. Every request is answered by v1, with no errors.

*(switch back to slides)*

### Shreejay: Slide 3, Our demo setup (~50 s)
> Everything runs on one laptop in Minikube. On the left is our pipeline, written as code in
> `app.pipecd.yaml`. It has six stages: start the new version as a canary on 25% of the pods,
> analyse it, grow it to 50%, analyse again, promote it to 100%, then clean up. The analysis calls
> the canary every 10 seconds and expects HTTP 200. Two failures and the stage fails. With
> `autoRollback: true`, PipeCD then undoes everything on its own.
>
> Our app has three versions. v1 is stable. **v2 is deliberately broken.** It returns HTTP 500,
> but its health check still passes, so Kubernetes thinks it's fine. v3 is the fix.
> To release, we only change the image tag in Git and push. Let's release v2.

**▶ DEMO: Saish runs `./scripts/release.sh v2`**
> That's the whole release: a one-line change, a commit, and a push. Within about 10 seconds PipeCD
> picks it up. In the console it says *"Sync progressively because of updating image from v1 to v2."*
> In the traffic terminal you can see red errors: about one in five requests now hits v2.

*(switch back to slides while the analysis runs)*

### Shreejay: Slide 4, PipeCD in a nutshell (~40 s, while ANALYSIS runs)
> While that runs, here's what's happening behind the scenes. PipeCD has two parts. The
> **Control Plane** is the web console and API. It stores history and coordinates, but never touches
> the cluster. **piped** is a small agent running next to the cluster. It watched our repo, saw the
> new commit, planned the deployment, and is running the analysis right now. It only makes outbound
> connections, so cluster credentials never leave the cluster. The same model also works for
> Terraform, ECS, Lambda and Cloud Run. Let's see what the analysis decided.

**▶ DEMO: Saish switches to the console (deployment page) and the traffic terminal**
> The ANALYSIS stage turned **red**: it got HTTP 500 twice. PipeCD skipped the remaining stages and
> ran **ROLLBACK** by itself. In the traffic terminal it's back to **v1 OK x20**, no errors. Nobody
> touched the cluster.

*(switch back to slides)*

### Chaitanya: Slide 5, Faulty v2: automatic rollback (~40 s)
> To recap what we just saw: the canary served about 20% of traffic, the analysis caught the 500s,
> and the rollback deleted the canary and re-applied v1. In our test run the broken version was
> live for about 28 seconds. Only about 22% of requests in that window were affected, and the main
> deployment never changed. Now the developer pushes the fix.

**▶ DEMO: Saish runs `./scripts/release.sh v3`**
> Same pipeline, new version. The canary is starting. In the terminal you can see v3 taking about
> one request in five, and all of them succeed.

*(switch back to slides)*

### Chaitanya: Slide 6, Fixed v3: progressive rollout (~60–90 s, while v3 rolls out)
> This chart is from our test run. It shows v3's share of live traffic over time. At the first canary
> step it gets about 19%, one new pod out of five. After the analysis passes, PipeCD grows the canary
> to 50% and v3 gets about 33%. After the second analysis it's promoted to 100%.
> *(glance at demo)* We're at the second step now. *(when done)* All six stages are green.

**▶ DEMO: Saish shows all 6 stages green + terminal `v3 OK x20`**
> Every request is now served by v3, with zero errors during the whole rollout.

*(switch back to slides)*

### Chaitanya: Slide 7, Results & takeaways (~45 s)
> To sum up: the broken build was live for about 28 seconds, and the rollback took about 2 seconds
> with no human involved. The fix rolled out in steps with zero errors. Our three takeaways: health
> checks don't prove correctness, and only the analysis caught v2. Releases and rollbacks happened
> without anyone running kubectl, and Git gives us a full audit trail. As future scope we'd add
> Prometheus metrics for the analysis, exact traffic weights with Istio, and PipeCD's Event Watcher
> to connect it to CI.

### Chaitanya: Slide 8, Thank you (~10 s)
> Everything we showed, including scripts and setup steps, is in our public repo on the slide.
> Thank you.

**Total ≈ 8–9 min**, including the two pipeline waits.

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

### B3. Screen layout
| Window | Content |
|---|---|
| Browser tab 1 | GitHub repo page (`manifests/web/`) |
| Browser tab 2 | PipeCD console, **Deployments** page (logged in) |
| Terminal 2 | `./scripts/traffic.sh`, started before the talk and left running |
| Terminal 3 | in the repo folder, ready to type `./scripts/release.sh v2` |
| Slides | PowerPoint / Google Slides presenter view |

Tip: place the console and Terminal 2 side by side on one screen, so a single switch shows both.

### B4. Live sequence (matches the ▶ cues)
| # | Cue | Action | What the audience sees |
|---|---|---|---|
| 1 | Slide 2 | Show GitHub tab, then console + Terminal 2 | app on v1, `v1 OK x20` |
| 2 | Slide 3 | Terminal 3: `./scripts/release.sh v2` | diff `v1 → v2`, "pushed …" |
| 3 | +10–20 s | Console → click the new deployment | K8S_CANARY_ROLLOUT running; Terminal 2: `v2 ERR x4` |
| 4 | Slide 4 | Switch to slides, talk ~40 s | |
| 5 | Slide 4 ▶ | Back to console | ANALYSIS ✖ red, ROLLBACK ✔; Terminal 2 back to `v1 OK x20` |
| 6 | Slide 5 ▶ | Terminal 3: `./scripts/release.sh v3` | new deployment starts; `v3 OK x4` |
| 7 | Slide 6 | Talk; peek at the console at each stage | 25% → analysis ✔ → 50% (`v3 OK x6–7`) → analysis ✔ |
| 8 | Slide 6 ▶ | Show the console | all 6 stages ✔; Terminal 2 `v3 OK x20` |

Timing: from the v2 push to rollback takes **~40–60 s**. The full v3 rollout takes **~2.5–3 min**.

Optional visuals: to show the broken page during step 3, run
`kubectl -n demo port-forward deploy/web-canary 9090:8080` and open localhost:9090.
To show the green v3 page at the end, run `kubectl -n demo port-forward svc/web 9091:8080`.

### B5. If something goes wrong
| Problem | Fix |
|---|---|
| No new deployment appears after a push | Wait 20 s and click REFRESH. Check `git log origin/main -1`. Check logs: `kubectl logs -n pipecd deploy/piped --tail=20` |
| Console won't load | The port-forward died. Re-run `kubectl port-forward -n pipecd svc/pipecd 8080` |
| `traffic.sh` says the pod already exists | Run `kubectl -n demo delete pod traffic`, then start it again |
| `git push` rejected | `git pull --rebase && git push` |
| Something breaks live | Switch to slides 5 and 6. They show the real screenshots and data from our verified run |

### B6. After the demo (to repeat it)
`./scripts/release.sh v1`, then wait for SUCCESS. That's the reset.
To shut down: `minikube stop -p pipecd-demo`.
