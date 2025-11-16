#!/bin/bash
# Simple Kubernetes Deployment Script

set -e

echo "========================================="
echo "   Kubernetes Deployment Script"
echo "========================================="

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

# Step 1: Check minikube
echo -e "\n[Step 1/6] Checking Minikube..."
if ! minikube status &> /dev/null; then
    echo "Starting Minikube..."
    minikube start
else
    echo "✓ Minikube is running"
fi

# Step 2: Configure Docker
echo -e "\n[Step 2/6] Configuring Docker..."
eval $(minikube docker-env --shell bash 2>/dev/null)
echo "✓ Docker configured to use Minikube"

# Step 3: Build images
echo -e "\n[Step 3/6] Building Docker images..."
echo "  Building backend..."
docker build -t backend:latest ./backend
echo "  Building frontend..."
docker build -t frontend:latest ./frontend
echo "✓ Images built successfully"

# Step 4: Deploy to Kubernetes
echo -e "\n[Step 4/6] Deploying to Kubernetes..."
kubectl apply -f k8s/ldap.yaml
kubectl apply -f k8s/backend.yaml
kubectl apply -f k8s/frontend.yaml
echo "✓ Resources deployed"

# Step 5: Wait for pods
echo -e "\n[Step 5/6] Waiting for pods to be ready..."
echo "  Waiting for LDAP..."
kubectl wait --for=condition=ready pod -l app=ldap --timeout=300s
echo "  Waiting for backend..."
kubectl wait --for=condition=ready pod -l app=backend --timeout=300s
echo "  Waiting for frontend..."
kubectl wait --for=condition=ready pod -l app=frontend --timeout=300s
echo "✓ All pods are ready"

# Step 6: Show status
echo -e "\n[Step 6/6] Deployment Status:"
kubectl get pods
echo ""
kubectl get services

# Start port forwarding
echo -e "\n========================================="
echo "   Starting Port Forwarding"
echo "========================================="
echo ""
echo "Access your application at:"
echo "  Frontend: http://${SERVER_IP}:8080"
echo "  Backend:  http://${SERVER_IP}:5000"
echo ""
echo "Login credentials:"
echo "  Username: dahituv"
echo "  Password: password123"
echo ""
echo "Press Ctrl+C to stop"
echo "========================================="
echo ""

# Cleanup function
cleanup() {
    echo -e "\n\nStopping port forwarding..."
    kill $FRONTEND_PID 2>/dev/null || true
    kill $BACKEND_PID 2>/dev/null || true
    exit 0
}

trap cleanup SIGINT SIGTERM

# Start port forwarding
kubectl port-forward service/frontend 8080:8080 --address 0.0.0.0 &
FRONTEND_PID=$!

kubectl port-forward service/backend 5000:5000 --address 0.0.0.0 &
BACKEND_PID=$!

# Wait
wait $FRONTEND_PID $BACKEND_PID

