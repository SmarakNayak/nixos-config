#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/configuration.nix"

# Available power configurations
CONFIGS=(
  "tlp"
  "auto-cpufreq"
  "ppd"
  "system76"
  "powertop"
  "minimal"
)

show_usage() {
  echo "Usage: $0 <config> [--test]"
  echo "       $0 --test-all"
  echo ""
  echo "Available configs:"
  for config in "${CONFIGS[@]}"; do
    echo "  - $config"
  done
  echo ""
  echo "Options:"
  echo "  --test        Run 5-minute powerstat test after switching (requires sudo)"
  echo "  --test-all    Test all configurations automatically"
  echo ""
  echo "Examples:"
  echo "  $0 ppd                   # Switch to PPD"
  echo "  $0 auto-cpufreq --test   # Switch and run powerstat test"
  echo "  $0 --test-all            # Test all configs automatically"
}

run_test() {
  local config=$1

  echo "==> Waiting 30 seconds for system to settle..."
  sleep 30

  echo "==> Running 5-minute powerstat test..."
  echo "==> (60 second delay, then 5 minutes of measurement)"
  echo ""

  TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  LOG_FILE="$SCRIPT_DIR/powerstat_${config}_${TIMESTAMP}.log"

  sudo powerstat -d 60 -z 5m | tee "$LOG_FILE"

  echo ""
  echo "==> Test complete! Results saved to:"
  echo "    $LOG_FILE"

  # Extract summary
  if grep -q "Average" "$LOG_FILE"; then
    echo ""
    echo "==> Summary:"
    grep "Average" "$LOG_FILE" || true
  fi

  echo "$LOG_FILE"
}

switch_config() {
  local config=$1

  # Determine the power management file to use
  if [[ "$config" == "tlp" ]]; then
    POWER_FILE="./power-management-tlp.nix"
  else
    POWER_FILE="./power-management-${config}.nix"
  fi

  echo "==> Switching to power config: $config"
  echo "==> Power management file: $POWER_FILE"

  # Update configuration.nix import
  sed -i "s|./power-management.*\.nix|$POWER_FILE|g" "$CONFIG_FILE"

  echo "==> Updated $CONFIG_FILE"
  echo "==> Building and switching system configuration..."

  # Rebuild system (using flake)
  cd "$SCRIPT_DIR/../.."
  sudo nixos-rebuild switch --flake .#msi-laptop

  echo ""
  echo "==> Successfully switched to $config power configuration!"
  echo ""

  # Set power profile for profile-based systems (twice for reliability)
  case "$config" in
    ppd)
      echo "==> Setting PPD to power-saver profile..."
      powerprofilesctl set power-saver || echo "Warning: Failed to set PPD profile"
      sleep 2
      powerprofilesctl set power-saver || echo "Warning: Failed to set PPD profile (2nd attempt)"
      ;;
    system76)
      echo "==> Setting system76-power to battery profile..."
      system76-power profile battery || echo "Warning: Failed to set system76 profile"
      sleep 2
      system76-power profile battery || echo "Warning: Failed to set system76 profile (2nd attempt)"
      ;;
  esac
  echo ""
}

# Check for --test-all
if [[ $# -eq 1 && $1 == "--test-all" ]]; then
  echo "======================================"
  echo "Testing all power configurations"
  echo "======================================"
  echo ""
  echo "This will take approximately $((${#CONFIGS[@]} * 7)) minutes"
  echo "(6 minutes per config: 30s settle + 60s delay + 5min test + rebuild time)"
  echo ""
  read -p "Continue? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi

  LOG_FILES=()

  for config in "${CONFIGS[@]}"; do
    echo ""
    echo "======================================"
    echo "Testing: $config"
    echo "======================================"
    echo ""

    switch_config "$config"
    LOG_FILE=$(run_test "$config")
    LOG_FILES+=("$LOG_FILE")

    echo ""
  done

  # Show summary of all tests
  echo ""
  echo "======================================"
  echo "All tests complete!"
  echo "======================================"
  echo ""
  echo "Results summary:"
  echo ""

  for log in "${LOG_FILES[@]}"; do
    config=$(basename "$log" | sed 's/powerstat_\(.*\)_[0-9_]*.log/\1/')
    echo "[$config]"
    grep "Average" "$log" 2>/dev/null || echo "  No results found"
    echo ""
  done

  exit 0
fi

# Original single-config logic
if [[ $# -lt 1 ]]; then
  show_usage
  exit 1
fi

CONFIG=$1
RUN_TEST=false

if [[ $# -eq 2 && $2 == "--test" ]]; then
  RUN_TEST=true
fi

# Validate config choice
if [[ ! " ${CONFIGS[@]} " =~ " ${CONFIG} " ]]; then
  echo "Error: Invalid config '$CONFIG'"
  echo ""
  show_usage
  exit 1
fi

switch_config "$CONFIG"

if [[ "$RUN_TEST" == true ]]; then
  run_test "$CONFIG"
fi
