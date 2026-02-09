# ☁️ Cloud Native Demo App

A GitOps-powered demo application deployed on **Azure AKS** via **ArgoCD**, with CI/CD through **GitHub Actions** and secrets managed by **External Secrets Operator** pulling from **Azure Key Vault**.

![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?logo=kubernetes&logoColor=white)
![ArgoCD](https://img.shields.io/badge/ArgoCD-EF7B4D?logo=argo&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?logo=terraform&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?logo=github-actions&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-0078D4?logo=microsoft-azure&logoColor=white)

---

## 📁 Project Structure

```
demo-app/
├── .github/
│   └── workflows/
│       └── ci-cd.yaml              # GitHub Actions CI/CD pipeline
├── src/                             # Application source code
│   ├── index.html
│   ├── css/
│   │   └── style.css
│   └── js/
│       └── app.js
├── k8s/
│   ├── base/                        # Kubernetes manifests (watched by ArgoCD)
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── ingress.yaml
│   │   ├── network-policy.yaml
│   │   └── external-secret.yaml
│   └── argocd/
│       └── application.yaml         # ArgoCD Application CR
├── Dockerfile
├── docker-entrypoint.sh             # Injects secrets into HTML at runtime
├── nginx.conf                       # Custom nginx configuration
├── .dockerignore
├── .gitignore
└── README.md
```

---

## 🔄 How It Works

```
Developer pushes code ──▶ GitHub Actions builds image ──▶ Pushes to ACR
                                        │
                                        ▼
                              Updates k8s/base/deployment.yaml with new tag
                                        │
                                        ▼
                         ArgoCD detects manifest change ──▶ Syncs to AKS
                                                                │
                                                                ▼
                                                External Secrets Operator
                                                pulls secret from Key Vault
                                                        │
                                                        ▼
                                                  App displays the
                                                  secret on the page
```

1. **Push code** — any change to `src/`, `Dockerfile`, `nginx.conf`, or `docker-entrypoint.sh` triggers the pipeline.
2. **Build & Push** — GitHub Actions builds a multi-arch Docker image and pushes it to your Azure Container Registry.
3. **Update Manifests** — the pipeline updates the image tag in `k8s/base/deployment.yaml` and commits back to the repo.
4. **ArgoCD Sync** — ArgoCD watches the `k8s/base/` directory and automatically deploys changes to your AKS cluster.
5. **Secrets** — External Secrets Operator syncs `secret-message` from Azure Key Vault into a Kubernetes secret, which is injected as an env var into the app.

---

## 🚀 Setup

### Prerequisites

- Azure AKS cluster (provisioned via Terraform)
- ArgoCD installed on the cluster
- External Secrets Operator installed with a `ClusterSecretStore` pointing to Azure Key Vault
- Azure Container Registry (ACR)
- cert-manager with a `letsencrypt` ClusterIssuer (for TLS)
- NGINX Ingress Controller

---

### Step 1: Configure GitHub Secrets & Variables

Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions**.

#### 🔒 Secrets (Settings → Secrets → Actions → New repository secret)

| Secret Name    | Description                                      | Example                 |
|----------------|--------------------------------------------------|-------------------------|
| `ACR_NAME`     | Your Azure Container Registry name (without `.azurecr.io`) | `myacrregistry`         |
| `ACR_USERNAME` | ACR admin username or service principal client ID | `myacrregistry`         |
| `ACR_PASSWORD` | ACR admin password or service principal secret    | `xxxxxxxx-xxxx-xxxx`    |

> **Tip:** You can find ACR credentials in the Azure Portal under your Container Registry → **Access keys** (enable Admin user), or use a service principal for production setups.

#### No Variables Needed

The previous setup used `APP_NAME` and `APP_PATH` variables — those are no longer necessary. The image name is hardcoded as `demo-app` in the workflow, and the Dockerfile is now at the repo root.

---

### Step 2: Create the Azure Key Vault Secret

This app demonstrates **External Secrets Operator** pulling a secret from Azure Key Vault and displaying it on the page.

Create a secret called `secret-message` in your Azure Key Vault:

```bash
# Replace <YOUR_KEYVAULT_NAME> with your actual Key Vault name
az keyvault secret set \
  --vault-name <YOUR_KEYVAULT_NAME> \
  --name "secret-message" \
  --value "Hello from Azure Key Vault! 🔐"
```

You can set the value to anything you want — it will appear on the app's **Vault Secret** section.

---

### Step 3: Configure the External Secret

Edit `k8s/base/external-secret.yaml` if your setup differs from the defaults:

```yaml
spec:
  secretStoreRef:
    name: azure-keyvault          # ← Match your ClusterSecretStore name
    kind: ClusterSecretStore       # ← Change to SecretStore if namespace-scoped
  data:
    - secretKey: SECRET_MESSAGE
      remoteRef:
        key: secret-message        # ← Must match the Key Vault secret name above
```

**How the flow works:**

| Step | Component | What happens |
|------|-----------|-------------|
| 1 | Azure Key Vault | Stores the secret `secret-message` |
| 2 | ExternalSecret CR | Tells ESO to pull `secret-message` from Key Vault |
| 3 | ESO | Creates a K8s Secret called `demo-app-secret` |
| 4 | Deployment | Mounts all keys from `demo-app-secret` as env vars via `envFrom` |
| 5 | `docker-entrypoint.sh` | Reads `SECRET_MESSAGE` env var and injects it into the HTML |
| 6 | Browser | Displays the secret on the page |

---

### Step 4: Update Manifests for Your Environment

A few values need to be updated to match your setup:

**`k8s/base/deployment.yaml`** — update the initial image (GitHub Actions will manage this after the first run):
```yaml
image: <YOUR_ACR_NAME>.azurecr.io/demo-app:1
```

**`k8s/base/ingress.yaml`** — update the hostname:
```yaml
rules:
  - host: your-app.your-domain.com
tls:
  - hosts:
      - your-app.your-domain.com
```

**`k8s/argocd/application.yaml`** — update the repo URL and target namespace:
```yaml
source:
  repoURL: https://github.com/<YOUR_USERNAME>/demo-app.git
destination:
  namespace: default    # ← change if deploying to a different namespace
```

---

### Step 5: Deploy the ArgoCD Application

Apply the ArgoCD Application to your cluster:

```bash
kubectl apply -f k8s/argocd/application.yaml
```

ArgoCD will now watch the `k8s/base/` directory and auto-sync any changes.

---

### Step 6: Push Code & Watch It Deploy

```bash
git add .
git commit -m "initial commit"
git push origin main
```

GitHub Actions will build the image, push to ACR, update the deployment manifest, and ArgoCD will pick it up and deploy it to your cluster.

---

## 🔧 Local Development

Build and run locally to test:

```bash
# Build
docker build -t demo-app .

# Run (with a test secret)
docker run -p 8080:80 -e SECRET_MESSAGE="Hello from local dev!" demo-app

# Visit http://localhost:8080
```

---

## 📝 Customization

- **Change the domain** — edit `k8s/base/ingress.yaml`
- **Change replicas** — edit `k8s/base/deployment.yaml`
- **Add more secrets** — add entries to `external-secret.yaml` and reference them in the deployment's `envFrom`
- **Change the app** — edit files in `src/` and push — the pipeline handles everything else

---

## 🏗️ Architecture

```
┌─────────────┐     ┌──────────────┐     ┌──────────────────┐
│  Developer   │────▶│   GitHub     │────▶│  GitHub Actions  │
│  git push    │     │   Repo       │     │  CI Pipeline     │
└─────────────┘     └──────┬───────┘     └────────┬─────────┘
                           │                       │
                           │  manifests updated     │  docker push
                           │                       ▼
                    ┌──────▼───────┐     ┌──────────────────┐
                    │   ArgoCD     │     │  Azure Container  │
                    │   watches    │     │  Registry (ACR)   │
                    │   manifests  │     └──────────────────┘
                    └──────┬───────┘
                           │  sync
                           ▼
                    ┌──────────────────────────────────────┐
                    │         Azure AKS Cluster             │
                    │  ┌────────────┐  ┌────────────────┐  │
                    │  │  App Pods  │  │ External Secret │  │
                    │  │  (nginx)   │  │  Operator       │  │
                    │  └────────────┘  └───────┬────────┘  │
                    │                          │            │
                    └──────────────────────────┼────────────┘
                                               │
                                        ┌──────▼───────┐
                                        │  Azure Key   │
                                        │  Vault       │
                                        └──────────────┘
```
# demo-app
