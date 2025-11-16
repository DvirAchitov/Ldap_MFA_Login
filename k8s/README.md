# Kubernetes Deployment

Simple Kubernetes setup for your LDAP authentication application.

## 🚀 Quick Start

```bash
./k8s/deploy.sh
```

That's it! The script will:
1. ✅ Check/start Minikube
2. ✅ Build Docker images  
3. ✅ Deploy 3 pods (LDAP, Backend, Frontend)
4. ✅ Wait for everything to be ready
5. ✅ Start port forwarding automatically

## 📦 What Gets Deployed

- **LDAP Pod** (`ldap-0`) - User directory with Bitnami OpenLDAP
- **Backend Pod** - Flask API server
- **Frontend Pod** - Web interface

## 🌐 Access the Application

The deploy script shows you the URLs:
```
Frontend: http://YOUR_IP:8080
Backend:  http://YOUR_IP:5000
```

## 👤 Login

- **Username:** `dahituv`
- **Password:** `password123`

## 🔧 Manual Commands

### Deploy everything:
```bash
kubectl apply -f k8s/
```

### Check status:
```bash
kubectl get pods
kubectl get services
```

### View logs:
```bash
kubectl logs ldap-0
kubectl logs -l app=backend
kubectl logs -l app=frontend
```

### Port forward manually:
```bash
kubectl port-forward service/frontend 8080:8080 --address 0.0.0.0 &
kubectl port-forward service/backend 5000:5000 --address 0.0.0.0 &
```

### Delete everything:
```bash
kubectl delete -f k8s/
kubectl delete pvc --all
```

## 🔄 Reset Everything

You can either run the manual commands below or use the convenience script `./k8s/cleanup.sh` which stops port-forwarding and removes all deployed resources and PVCs.

Manual (existing):
```bash
# Stop port forwarding
pkill -f "kubectl port-forward"

# Delete all resources
kubectl delete -f k8s/
kubectl delete pvc --all

# Redeploy
./k8s/deploy.sh
```

Or use the cleanup script (recommended for convenience):
```bash
chmod +x k8s/cleanup.sh
./k8s/cleanup.sh

# (Optional) Redeploy after cleanup:
./k8s/deploy.sh
```

## 👤 Add Users

To add a new user with MFA:

```bash
chmod +x k8s/add_user.sh
./k8s/add_user.sh -user alice -name "Alice Wonder" -password alice123 -mail alice@example.com
```

See `k8s/README_ADD_USER.md` for full documentation.

## 📁 Files

- `ldap.yaml` - LDAP Deployment and Service
- `backend.yaml` - Backend Deployment and Service
- `frontend.yaml` - Frontend Deployment and Service
- `deploy.sh` - Automated deployment script
- `add_user.sh` - Add new users with MFA
- `cleanup.sh` - Remove all resources
- `README_ADD_USER.md` - User management docs

Simple and clean! 🎉
