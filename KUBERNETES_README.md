# Data Fortress - Kubernetes Deployment Guide

A complete file upload application with backup capabilities designed for Kubernetes deployment. This application serves as a dummy workload for backup and recovery testing scenarios.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │    Backend      │    │   MongoDB       │
│   (React/Nginx) │◄──►│   (Node.js)     │◄──►│   (Database)    │
│   Port: 80      │    │   Port: 5000    │    │   Port: 27017   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Frontend       │    │   Backend       │    │   MongoDB       │
│  Service        │    │   Service       │    │   Service       │
│  (NodePort)     │    │   (ClusterIP)   │    │   (ClusterIP)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Uploads       │    │   Backup        │    │   MongoDB       │
│   PVC (1Gi)     │    │   CronJob       │    │   PVC (2Gi)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📋 Prerequisites

- Kubernetes cluster (v1.20+)
- `kubectl` configured to access your cluster
- Docker images pushed to registry:
  - `shrinidhiupadhyaya/datafortress-frontend:latest`
  - `shrinidhiupadhyaya/datafortress-backend:latest`
  - `shrinidhiupadhyaya/datafortress-backup:latest`

## 🚀 Quick Deployment

### 1. Deploy All Resources at Once

```bash
# Clone the repository
git clone https://github.com/Shrinidhi972004/file-upload.git
cd file-upload

# Deploy everything
kubectl apply -f k8s/
```

### 2. Verify Deployment

```bash
# Check all resources
kubectl get all -n datafortress

# Check persistent volumes
kubectl get pvc -n datafortress
```

## 📁 Kubernetes Resources

### Files Structure
```
k8s/
├── namespace.yaml           # Creates 'datafortress' namespace
├── mongo-pvc.yaml          # MongoDB persistent storage (2Gi)
├── uploads-pvc.yaml        # File uploads storage (1Gi)
├── mongo-deployment.yaml   # MongoDB database deployment
├── mongo-service.yaml      # MongoDB internal service
├── backend-deployment.yaml # Node.js API deployment
├── backend-service.yaml    # Backend API service
├── frontend-deployment.yaml# React frontend deployment
├── frontend-service.yaml   # Frontend service (NodePort)
└── backup-cronjob.yaml     # Automated backup job
```

## 🔧 Step-by-Step Deployment

### Step 1: Create Namespace
```bash
kubectl apply -f k8s/namespace.yaml
```

### Step 2: Create Storage
```bash
kubectl apply -f k8s/mongo-pvc.yaml
kubectl apply -f k8s/uploads-pvc.yaml
```

### Step 3: Deploy Database
```bash
kubectl apply -f k8s/mongo-deployment.yaml
kubectl apply -f k8s/mongo-service.yaml

# Wait for MongoDB to be ready
kubectl wait --for=condition=ready pod -l app=mongo -n datafortress --timeout=300s
```

### Step 4: Deploy Backend API
```bash
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml

# Wait for backend to be ready
kubectl wait --for=condition=ready pod -l app=datafortress-backend -n datafortress --timeout=300s
```

### Step 5: Deploy Frontend
```bash
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml

# Wait for frontend to be ready
kubectl wait --for=condition=ready pod -l app=datafortress-frontend -n datafortress --timeout=300s
```

### Step 6: Deploy Backup System
```bash
kubectl apply -f k8s/backup-cronjob.yaml
```

## 🌐 Accessing the Application

### Method 1: Port Forwarding (Recommended for Testing)

```bash
# Forward frontend (Web UI)
kubectl port-forward -n datafortress service/datafortress-frontend 3000:80 &

# Forward backend (API)
kubectl port-forward -n datafortress service/backend 5000:5000 &

# Access URLs:
# Frontend: http://localhost:3000
# Backend API: http://localhost:5000
```

### Method 2: NodePort Access

```bash
# Get the NodePort
kubectl get service datafortress-frontend -n datafortress

# Access via any node IP on the assigned NodePort
# Example: http://NODE_IP:30080
```

### Method 3: Load Balancer (Cloud Environments)

For cloud deployments, change the frontend service type:

```yaml
# In k8s/frontend-service.yaml
spec:
  type: LoadBalancer  # Change from NodePort
  ports:
    - port: 80
      targetPort: 80
```

## 📊 Monitoring and Health Checks

### Check Application Status
```bash
# Overall status
kubectl get all -n datafortress

# Pod logs
kubectl logs -n datafortress deployment/datafortress-frontend
kubectl logs -n datafortress deployment/datafortress-backend
kubectl logs -n datafortress deployment/mongo

# Health endpoints
kubectl port-forward -n datafortress service/backend 5000:5000 &
curl http://localhost:5000/health
```

### Check Storage
```bash
# Persistent Volume Claims
kubectl get pvc -n datafortress

# Storage usage (requires metrics-server)
kubectl top pods -n datafortress
```

## 💾 Backup and Recovery

### Manual Backup
```bash
# Run backup job manually
kubectl create job --from=cronjob/datafortress-backup manual-backup-$(date +%s) -n datafortress

# Check backup job status
kubectl get jobs -n datafortress
```

### Automated Backup
The backup CronJob runs daily at 2 AM UTC. To modify the schedule:

```yaml
# In k8s/backup-cronjob.yaml
spec:
  schedule: "0 2 * * *"  # Change this cron expression
```

### AWS S3 Configuration
For backup to work, you need AWS credentials:

```bash
# Create a secret with AWS credentials
kubectl create secret generic aws-credentials -n datafortress \
  --from-literal=AWS_ACCESS_KEY_ID=your_access_key \
  --from-literal=AWS_SECRET_ACCESS_KEY=your_secret_key

# Update backup-cronjob.yaml to use the secret
```

## 🔧 Configuration

### Environment Variables

#### Backend Configuration
```yaml
env:
  - name: MONGODB_URI
    value: mongodb://mongo:27017/fileupload
  - name: PORT
    value: "5000"
  - name: NODE_ENV
    value: production
  - name: UPLOAD_DIR
    value: /app/uploads
```

#### Backup Configuration
```yaml
env:
  - name: MONGODB_URI
    value: mongodb://mongo:27017/fileupload
  - name: AWS_BUCKET
    value: datafortress-backups-shrinidhi
  - name: AWS_REGION
    value: ap-south-1
```

### Resource Limits (Recommended)
Add resource limits for production:

```yaml
# Example for backend deployment
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

## 🧪 Testing the Application

### 1. Upload Files
```bash
# Port-forward to access the application
kubectl port-forward -n datafortress service/datafortress-frontend 3000:80

# Open http://localhost:3000 in your browser
# Upload various file types to test functionality
```

### 2. API Testing
```bash
# Port-forward backend
kubectl port-forward -n datafortress service/backend 5000:5000

# Test API endpoints
curl http://localhost:5000/health
curl http://localhost:5000/api/files
```

### 3. Database Testing
```bash
# Access MongoDB directly
kubectl exec -it -n datafortress deployment/mongo -- mongosh

# In MongoDB shell:
use fileupload
db.files.find().pretty()
```

## 🛠️ Troubleshooting

### Common Issues

#### 1. Pods Not Starting
```bash
# Check pod status
kubectl get pods -n datafortress

# Check pod logs
kubectl logs -n datafortress <pod-name>

# Describe pod for events
kubectl describe pod -n datafortress <pod-name>
```

#### 2. Service Discovery Issues
```bash
# Check services
kubectl get services -n datafortress

# Test connectivity between pods
kubectl exec -it -n datafortress deployment/datafortress-backend -- nslookup mongo
```

#### 3. Storage Issues
```bash
# Check PVC status
kubectl get pvc -n datafortress

# Check persistent volumes
kubectl get pv

# Check storage class
kubectl get storageclass
```

#### 4. Frontend Can't Connect to Backend
- Ensure backend service is named "backend" (not "datafortress-backend")
- Check nginx configuration in frontend container
- Verify port-forwarding is working for both services

### Debug Commands
```bash
# Get all events in namespace
kubectl get events -n datafortress

# Port-forward for debugging
kubectl port-forward -n datafortress service/datafortress-frontend 8080:80
kubectl port-forward -n datafortress service/backend 8081:5000

# Exec into containers
kubectl exec -it -n datafortress deployment/datafortress-backend -- /bin/bash
kubectl exec -it -n datafortress deployment/datafortress-frontend -- /bin/sh
```

## 🧹 Cleanup

### Remove Application
```bash
# Delete all resources
kubectl delete -f k8s/

# Or delete namespace (removes everything)
kubectl delete namespace datafortress
```

### Stop Port Forwarding
```bash
# Kill all kubectl port-forward processes
pkill -f "kubectl port-forward"
```

## 🔄 Updates and Maintenance

### Update Application Images
```bash
# Update to new image version
kubectl set image deployment/datafortress-backend backend=shrinidhiupadhyaya/datafortress-backend:v2.0 -n datafortress
kubectl set image deployment/datafortress-frontend frontend=shrinidhiupadhyaya/datafortress-frontend:v2.0 -n datafortress

# Check rollout status
kubectl rollout status deployment/datafortress-backend -n datafortress
```

### Scale Application
```bash
# Scale frontend replicas
kubectl scale deployment datafortress-frontend --replicas=3 -n datafortress

# Scale backend replicas
kubectl scale deployment datafortress-backend --replicas=2 -n datafortress
```

## 🌍 Cloud Provider Specific Notes

### AWS EKS
- Use EBS storage classes for PVCs
- Configure ALB ingress for external access
- Use IAM roles for service accounts for backup S3 access

### Google GKE
- Use regional persistent disks
- Configure Google Cloud Load Balancer
- Use Workload Identity for backup storage access

### Azure AKS
- Use Azure Disk storage
- Configure Azure Load Balancer
- Use pod identity for backup storage access

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Hub Images](https://hub.docker.com/u/shrinidhiupadhyaya)
- [Node.js Best Practices](https://nodejs.org/en/docs/guides/)
- [React Deployment Guide](https://create-react-app.dev/docs/deployment/)

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section above
2. Review Kubernetes events: `kubectl get events -n datafortress`
3. Check application logs for specific error messages
4. Verify all prerequisites are met

---

**Happy Deploying! 🚀**

This application is designed to be a robust dummy workload for testing backup and recovery scenarios in Kubernetes environments.
