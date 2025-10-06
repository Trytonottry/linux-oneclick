#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CHECK_MARK="✅"
CROSS_MARK="❌"
SERVER_ICON="🖥️"
NETWORK_ICON="🌐"

hosts=(
    "Рабочий ПК:10.147.19.25:22"
    "Мини-ПК:10.147.19.210:22"
    "Orange Pi:10.147.19.180:22"
)

check_ssh_port() {
    local host_entry=$1
    local name=$(echo "$host_entry" | cut -d':' -f1)
    local host=$(echo "$host_entry" | cut -d':' -f2)
    local port=$(echo "$host_entry" | cut -d':' -f3)
    local timeout=5

    if nc -z -w "$timeout" "$host" "$port" &> /dev/null; then
        echo -e "${GREEN}${CHECK_MARK} $name ($host:$port) - ${GREEN}Host online${NC}"
        return 0
    else
        echo -e "${RED}${CROSS_MARK} $name ($host:$port) - ${RED}Host offline${NC}"
        return 1
    fi
}

echo -e "\n${BLUE}${NETWORK_ICON} NETWORK MONITORING ${NETWORK_ICON}${NC}"
echo -e "${BLUE}═══════════════════════════${NC}"

echo -e "\n${CYAN}${SERVER_ICON} Checking ZeroTier devices access...${NC}"
echo -e "${BLUE}═══════════════════════════════════${NC}"

available=0
unavailable=0

for host_entry in "${hosts[@]}"; do
    if check_ssh_port "$host_entry"; then
        ((available++))
    else
        ((unavailable++))
    fi
done

echo -e "${BLUE}═══════════════════════════════════${NC}"
echo -e "${CYAN}Devices Status Summary:${NC}"
echo -e "  ${GREEN}${CHECK_MARK} Online:  $available${NC}"
echo -e "  ${RED}${CROSS_MARK} Offline: $unavailable${NC}"
echo -e "  ${CYAN}📊 Total:    ${#hosts[@]}${NC}"

echo -e "\n${BLUE}${NETWORK_ICON} SUMMARY MONITORING ${NETWORK_ICON}${NC}"
echo -e "${BLUE}═════════════════════════════${NC}"

echo -e "${CYAN}${SERVER_ICON} Devices:${NC} ${GREEN}$available/${#hosts[@]}${NC} available"

if [ $unavailable -eq 0 ]; then
    echo -e "\n${GREEN}${CHECK_MARK} System status: ${GREEN}HEALTHY${NC}"
else
    echo -e "\n${YELLOW}${ERROR_ICON} System status: ${YELLOW}DEGRADED${NC}"
    echo -e "${YELLOW}Some devices are unreachable${NC}"
fi

if [ $unavailable -eq 0 ]; then
    exit 0
else
    exit 1
fi
