#!/bin/bash
# Cleanup script - removes all Kubernetes resources

echo "========================================="
echo "   Cleaning Up Kubernetes Resources"
echo "========================================="

# Stop port forwarding
echo -e "\n[1/3] Stopping port forwarding..."
pkill -f "kubectl port-forward" 2>/dev/null || true
echo "✓ Port forwarding stopped"

# Delete all resources
echo -e "\n[2/3] Deleting Kubernetes resources..."
kubectl delete -f k8s/ 2>/dev/null || true
echo "✓ Resources deleted"

# Delete persistent volumes
echo -e "\n[3/3] Deleting persistent volumes..."
kubectl delete pvc --all 2>/dev/null || true
echo "✓ Volumes deleted"

echo -e "\n========================================="
echo "   Cleanup Complete!"
echo "========================================="
echo ""
echo "To redeploy, run: ./k8s/deploy.sh"
echo ""

