#!/bin/bash

ACTION=$1
SSH_USER=$(whoami)
MASTER_IP=$(kubectl get nodes -o wide | awk '/controlplane/ {print $6; exit}')
NODE_IPS=$(kubectl get nodes -o wide | awk '!/controlplane/ && !/INTERNAL-IP/ {print $6}')
SUBNET=$(echo $MASTER_IP | awk -F. '{print $1"."$2"."$3".0/24"}')

install_master() {
  apt-get update -y
  apt-get install -y nfs-kernel-server
  mkdir -p /dockerdata-nfs
  chmod 777 /dockerdata-nfs
  chown nobody:nogroup /dockerdata-nfs
  echo "/dockerdata-nfs $SUBNET(rw,sync,no_root_squash,no_subtree_check)" >/etc/exports
  exportfs -ra
  systemctl restart nfs-kernel-server
}

install_workers() {
  echo "$NODE_IPS" | xargs -P 10 -I {} ssh -o StrictHostKeyChecking=no $SSH_USER@{} "
    sudo apt-get update -y
    sudo apt-get install -y nfs-common
    sudo mkdir -p /dockerdata-nfs
    if ! grep -q '/dockerdata-nfs' /etc/fstab; then
      echo '$MASTER_IP:/dockerdata-nfs /dockerdata-nfs nfs4 auto,_netdev,nofail,noatime,nolock,intr,proto=tcp 0 0' | sudo tee -a /etc/fstab
    fi
    sudo mount -a
  "
}

unmount_workers() {
  echo "$NODE_IPS" | xargs -P 10 -I {} ssh $SSH_USER@{} "
    sudo umount -f /dockerdata-nfs 2>/dev/null || true
  "
}

remount_workers() {
  echo "$NODE_IPS" | xargs -P 10 -I {} ssh $SSH_USER@{} "
    sudo mount -a
  "
}

cleanup_workers() {
  echo "$NODE_IPS" | xargs -P 10 -I {} ssh $SSH_USER@{} "
    sudo umount -f /dockerdata-nfs 2>/dev/null || true
    sudo sed -i '/dockerdata-nfs/d' /etc/fstab
    sudo rm -rf /dockerdata-nfs
  "
}

cleanup_master() {
  umount -f /dockerdata-nfs 2>/dev/null || true
  sed -i '/dockerdata-nfs/d' /etc/exports
  exportfs -ra
  rm -rf /dockerdata-nfs
}

case "$ACTION" in
  install)
    install_master
    install_workers
    ;;
  unmount)
    unmount_workers
    ;;
  remount)
    remount_workers
    ;;
  cleanup)
    cleanup_workers
    cleanup_master
    ;;
  *)
    echo "Usage: $0 {install|unmount|remount|cleanup}"
    ;;
esac


#for all sudo ./setup_nfs_cluster.sh install
#for unmount sudo ./setup_nfs_cluster.sh unmount
#for remount sudo ./setup_nfs_cluster.sh remount
#for full cleanup sudo ./setup_nfs_cluster.sh cleanup
