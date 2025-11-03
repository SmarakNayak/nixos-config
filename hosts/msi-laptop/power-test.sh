#!/usr/bin/env bash
set -e
set -o pipefail

SCRIPT_PATH=$(realpath "$0")

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
    "power-management-test-retry.nix"
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
        # Build JSON array of all configs
        local configs_json=$(printf '%s\n' "${CONFIGS[@]}" | jq -R . | jq -s .)
        cat > "$STATE_FILE" <<EOF
{
    "remaining_tests": $configs_json,
    "stage": "start",
    "current_config": null,
    "retry_count": 0,
    "started_at": "$(date -Iseconds)"
}
EOF
        mkdir -p "$RESULTS_DIR"
        mkdir -p "$FAILED_DIR"
        echo "Initialized test state"
    fi
}

# Read current state
get_remaining_tests() {
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "[]"
        return
    fi
    jq -r '.remaining_tests' "$STATE_FILE"
}

get_current_config() {
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "null"
        return
    fi
    jq -r '.current_config' "$STATE_FILE"
}

read_stage() {
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "start"
        return
    fi
    jq -r '.stage' "$STATE_FILE"
}

get_retry_count() {
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "0"
        return
    fi
    jq -r '.retry_count // 0' "$STATE_FILE"
}

# Update state
update_state() {
    local remaining_json=$1
    local stage=$2
    local current_config=$3
    local retry_count=${4:-0}
    cat > "$STATE_FILE" <<EOF
{
    "remaining_tests": $remaining_json,
    "stage": "$stage",
    "current_config": "$current_config",
    "retry_count": $retry_count,
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

# Force battery/power-saving mode for daemons
force_battery_mode() {
    local config=$1
    echo "Forcing power-saving mode for: $config"

    if [[ "$config" == *"ppd"* ]]; then
        echo "Setting power-profiles-daemon to power-saver..."
        powerprofilesctl set power-saver 2>/dev/null || true
        sleep 2
    elif [[ "$config" == *"tuned"* ]]; then
        echo "Setting tuned to powersave profile..."
        tuned-adm profile powersave 2>/dev/null || true
        sleep 2
    elif [[ "$config" == *"system76"* ]]; then
        echo "Setting system76-power to battery profile (running twice)..."
        system76-power profile battery 2>/dev/null || true
        sleep 2
        system76-power profile battery 2>/dev/null || true
        sleep 2
    fi
}

# Run powerstat test
run_powerstat() {
    local config=$1
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local logfile="$RESULTS_DIR/powerstat_${config%.nix}_${timestamp}.log"

    # Force battery/power-saving mode before testing
    force_battery_mode "$config"

    echo "Running powerstat..."
    powerstat 2>&1 | tee "$logfile"

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
    echo "   cd ~/nixos-config && nixos-rebuild switch --flake .#msi-laptop"
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

    local remaining_tests=$(get_remaining_tests)
    local stage=$(read_stage)
    local remaining_count=$(echo "$remaining_tests" | jq 'length')

    echo "================================"
    echo "Power Management Test Suite"
    echo "Tests remaining: $remaining_count"
    echo "Stage: $stage"
    echo "================================"

    # Check if we're done
    if [[ $remaining_count -eq 0 ]]; then
        disable_autologin
        exit 0
    fi

    # Get the first test from remaining list
    local config=$(echo "$remaining_tests" | jq -r '.[0]')

    echo "Current test: $config"
    echo "Remaining tests:"
    echo "$remaining_tests" | jq -r '.[]' | sed 's/^/  - /'
    echo ""

    case "$stage" in
        start|rebuild)
            echo "Stage: Applying config and rebuilding..."
            
            for (( attempt=1; attempt<=3; attempt++ )); do
                echo "Attempt $attempt/3 for config: $config"
                if apply_config "$config"; then
                    # Success - move to settle stage and reboot
                    update_state "$remaining_tests" "settle" "$config" 0
                    echo "Rebuild successful. Rebooting in 10 seconds..."
                    sleep 10
                    reboot
                    exit 0 # Exit after reboot command
                fi
                
                # Failure - log and retry
                echo "Rebuild failed (attempt $attempt/3)."
                if [[ $attempt -lt 3 ]]; then
                    echo "Retrying in 5 seconds..."
                    sleep 5
                fi
            done

            # All retries failed - skip to next config
            echo "Rebuild failed after 3 attempts. Skipping test and moving to next..."
            local new_remaining=$(echo "$remaining_tests" | jq '.[1:]')
            update_state "$new_remaining" "rebuild" "null" 0

            # Don't reboot, just run this script again to try next test
            echo "Continuing to next test in 5 seconds..."
            sleep 5
            exec "$SCRIPT_PATH" "$@"
            ;;

        settle)
            echo "Stage: System settling and running test..."
            run_powerstat "$config"

            # Remove completed test from queue
            local new_remaining=$(echo "$remaining_tests" | jq '.[1:]')
            local new_count=$(echo "$new_remaining" | jq 'length')

            if [[ $new_count -eq 0 ]]; then
                update_state "$new_remaining" "complete" "null" 0
            else
                update_state "$new_remaining" "rebuild" "null" 0
            fi

            echo "Test complete. Rebooting in 10 seconds for next test..."
            sleep 10
            reboot
            ;;

        complete)
            disable_autologin
            exit 0
            ;;
    esac
}

main "$@"
