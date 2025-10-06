#!/bin/bash
echo "=== NVMe Diagnostic for Acer A515-55 ==="
echo
echo "[1] PCIe devices:"
lspci | grep -i nvme || echo "No NVMe controller found in PCIe list."
echo
echo "[2] Kernel logs:"
dmesg | grep -i nvme || echo "No NVMe messages in kernel logs."
echo
echo "[3] Block devices:"
lsblk | grep nvme || echo "No NVMe block devices detected."
echo
echo "[4] Sysfs check:"
ls /sys/class/nvme/ 2>/dev/null || echo "No /sys/class/nvme entries."
echo
echo "[!] If nothing found above, controller likely not initializing (hardware or firmware issue)."

