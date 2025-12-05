# nfs-auto-installer-4-cluster
# README — NFS Cluster Setup Tool  
**Note:** This script provides an ideal and production-ready NFS setup for especially ONAP environments, especially for components like Strimzi Kafka, AAI, SDNC, and other stateful ONAP workloads that require persistent shared storage. of course you able to use it without ONAP environment. It is developed for basically ONAP and extended for all.

---

##  Contents
- Requirements  
- How It Works  
- Installation  
- Usage Modes  
- Validation  
- Supported Architecture  
- Troubleshooting  
- Advanced Scenarios  

---

##  Requirements

- This script must be executed on a **control-plane (master)** node.  
- The user running the script must have SSH access to all Kubernetes nodes.  
- A functional Kubernetes cluster with:
  - At least one control-plane node  
  - One or more worker nodes  
- `kubectl` must be configured and functional on the master.

---

##  How It Works

The script performs a fully automated NFS deployment across all cluster nodes.

### **Control-plane Node (NFS Server)**

1. Automatically detects the control-plane IP using `kubectl`.  
2. Derives the subnet automatically  
   Example: `10.10.10.11 → 10.10.10.0/24`  
3. Creates `/dockerdata-nfs` directory.  
4. Installs `nfs-kernel-server`.  
5. Configures `/etc/exports` properly.  
6. Starts the NFS service.

---

### **Worker Nodes (NFS Clients)**

For each worker node (in parallel):

1. Installs `nfs-common`.  
2. Creates `/dockerdata-nfs`.  
3. Updates `/etc/fstab` with the correct mount entry.  
4. Automatically mounts the NFS share.

---

### **Unmount / Remount / Cleanup**

Script includes additional modes for cluster maintenance:

- `unmount` → Detaches NFS from all worker nodes  
- `remount` → Re-mounts on all workers  
- `cleanup` → Removes all NFS server + client configuration  

---

## 🔧 Installation

Make the script executable:

```bash
chmod +x setup_nfs_cluster.sh
