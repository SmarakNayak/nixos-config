#!/usr/bin/env bash
set -e

# Power Management Testing Script with Reboot Support
# This script tests different power management configs and survives reboots

STATE_FILE="$HOME/.power-test-state.json"
RESULTS_DIR="$HOME/nixos-config/hosts/msi-laptop/power-test-results"
FAILED_DIR="$HOME/nixos-config/hosts/msi-laptop/power-test-failed"
CONFIG_FILE="$HOME/nixos-config/hosts/msi-laptop/configuration.nix"
FLAKE_DIR="$HOME/nixos-config"
HOSTNAME="msi-laptop"

# Configs to test (in order)
CONFIGS=(
    # Baseline
    "power-management-baseline.nix"

    # Individual feature tests (8 tests)
    "power-management-test-60hz.nix"
    "power-management-test-wifi.nix"
    "power-management-test-i915.nix"
    "power-management-test-laptop-mode.nix"
    "power-management-test-thermald.nix"
    "power-management-test-powertop.nix"
    "power-management-test-gpu-enabled.nix"
    "power-management-test-no-prime.nix"

    # Power daemon tests - daemons ONLY (5 tests)
    "power-management-test-ppd-only.nix"
    "power-management-test-tlp-only.nix"
    "power-management-test-auto-cpufreq-only.nix"
    "power-management-test-system76-only.nix"
    "power-management-test-tuned-only.nix"

    # Combined/realistic configurations (3 tests)
    "power-management-all-features.nix"      # All features, NO daemon
    "power-management-all-plus-tlp.nix"      # All features + TLP
    "power-management-all-plus-tuned.nix"    # All features + tuned
)

# Initialize state file if doesn't exist
init_state() {
    if [[ ! -f "$STATE_FILE" ]]; then
        cat > "$STATE_FILE" <<EOF
{
    "current_test": 0,
    "stage": "start",
    "started_at": "$(date -Iseconds)"
}
EOF
        mkdir -p "$RESULTS_DIR"
        mkdir -p "$FAILED_DIR"
        echo "Initialized test state"
    fi
}

# Read current state
read_state() {
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "0"
        return
    fi
    jq -r '.current_test' "$STATE_FILE"
}

read_stage() {
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "start"
        return
    fi
    jq -r '.stage' "$STATE_FILE"
}

# Update state
update_state() {
    local test_num=$1
    local stage=$2
    cat > "$STATE_FILE" <<EOF
{
    "current_test": $test_num,
    "stage": "$stage",
    "updated_at": "$(date -Iseconds)"
}
EOF
}

# Apply config and rebuild
apply_config() {
    local config=$1
    echo "Applying config: $config"

    # Backup current config
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup"

    # Replace the power management import line
    sed -i "s|./power-management.*\.nix|./$config|g" "$CONFIG_FILE"

    echo "Rebuilding NixOS with $config..."
    cd "$FLAKE_DIR"

    # Try rebuild, handle failure gracefully
    if ! sudo nixos-rebuild switch --flake ".#$HOSTNAME" 2>&1 | tee "$FAILED_DIR/rebuild_${config%.nix}_$(date +%Y%m%d_%H%M%S).log"; then
        echo "ERROR: Rebuild failed for $config"
        echo "Restoring backup configuration..."
        cp "$CONFIG_FILE.backup" "$CONFIG_FILE"

        # Log the failure
        echo "$config: FAILED - $(date -Iseconds)" >> "$FAILED_DIR/failed_tests.log"

        return 1
    fi

    return 0
}

# Run powerstat test
run_powerstat() {
    local config=$1
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local logfile="$RESULTS_DIR/powerstat_${config%.nix}_${timestamp}.log"

    echo "Waiting 60 seconds for system to settle..."
    sleep 60

    echo "Running powerstat for 7 minutes (420 seconds)..."
    powerstat -R -z 420 5 2>&1 | tee "$logfile"

    echo "Results saved to: $logfile"
}

# Disable autologin after testing is complete
disable_autologin() {
    echo ""
    echo "================================"
    echo "ALL TESTS COMPLETE!"
    echo "================================"
    echo ""
    echo "CRITICAL: Disable testing mode NOW!"
    echo ""
    echo "1. Edit configuration.nix and remove/comment:"
    echo "   ./power-testing-mode.nix"
    echo ""
    echo "2. Rebuild:"
    echo "   cd ~/nixos-config && sudo nixos-rebuild switch --flake .#msi-laptop"
    echo ""
    echo "Results are in: $RESULTS_DIR"
    echo ""

    # Remove state file
    rm -f "$STATE_FILE"

    # Disable this service so it doesn't run again
    systemctl --user disable power-test.service 2>/dev/null || true
}

# Main logic
main() {
    init_state

    local current_test=$(read_state)
    local stage=$(read_stage)
    local total_tests=${#CONFIGS[@]}

    echo "================================"
    echo "Power Management Test Suite"
    echo "Test $((current_test + 1))/$total_tests"
    echo "Stage: $stage"
    echo "================================"

    # Check if we're done
    if [[ $current_test -ge $total_tests ]]; then
        disable_autologin
        exit 0
    fi

    local config="${CONFIGS[$current_test]}"

    case "$stage" in
        start|rebuild)
            echo "Stage: Applying config and rebuilding..."

            # Try to apply config, skip to next test if it fails
            if ! apply_config "$config"; then
                echo "Skipping test due to rebuild failure, moving to next..."
                next_test=$((current_test + 1))
                if [[ $next_test -ge $total_tests ]]; then
                    update_state "$next_test" "complete"
                else
                    update_state "$next_test" "rebuild"
                fi

                # Don't reboot, just run this script again to try next test
                echo "Continuing to next test in 5 seconds..."
                sleep 5
                exec "$0" "$@"
            fi

            update_state "$current_test" "settle"

            echo "Rebooting in 10 seconds..."
            sleep 10
            sudo reboot
            ;;

        settle)
            echo "Stage: System settling and running test..."
            run_powerstat "$config"

            # Move to next test
            next_test=$((current_test + 1))
            if [[ $next_test -ge $total_tests ]]; then
                update_state "$next_test" "complete"
            else
                update_state "$next_test" "rebuild"
            fi

            echo "Test complete. Rebooting in 10 seconds for next test..."
            sleep 10
            sudo reboot
            ;;

        complete)
            disable_autologin
            exit 0
            ;;
    esac
}

main "$@"
