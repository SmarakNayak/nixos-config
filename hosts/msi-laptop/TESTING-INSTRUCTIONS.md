# Automated Power Management Testing

## Setup Instructions

### Step 1: Enable Testing Mode (SECURITY RISK!)

**WARNING: This enables autologin and passwordless sudo!**

Edit your `configuration.nix` and add this import:

```nix
imports = [
  ./hardware-configuration.nix
  ./power-management-minimal.nix  # or whatever you're currently using
  ./power-testing-mode.nix  # <-- ADD THIS LINE
  ../../modules/niri.nix
  ../../modules/hyprland.nix
];
```

Apply the changes:

```bash
cd ~/nixos-config
sudo nixos-rebuild switch --flake .#msi-laptop
```

### Step 2: Enable the Test Service

```bash
systemctl --user enable power-test.service
systemctl --user start power-test.service
```

### Step 3: Let It Run

The system will now:
1. Apply each power management config
2. Rebuild NixOS
3. Reboot automatically
4. Wait 60s for system to settle
5. Run powerstat for 7 minutes
6. Move to next config and reboot
7. Repeat for all 7 configs (~1.5 hours total)

**Don't touch the laptop during testing!** Just let it run.

### Step 4: Cleanup After Testing (CRITICAL FOR SECURITY!)

When all tests complete, the script will notify you. Then:

1. **REMOVE THE IMPORT** from `configuration.nix`:
   ```nix
   imports = [
     ./hardware-configuration.nix
     ./power-management-minimal.nix
     # ./power-testing-mode.nix  # <-- REMOVE OR COMMENT THIS LINE
     ../../modules/niri.nix
     ../../modules/hyprland.nix
   ];
   ```

2. **Rebuild** to disable autologin and passwordless sudo:
   ```bash
   cd ~/nixos-config
   sudo nixos-rebuild switch --flake .#msi-laptop
   ```

3. Results will be in: `~/nixos-config/hosts/msi-laptop/power-test-results/`

## Configs Being Tested (in order)

1. `power-management.nix` - TLP + powertop + thermald (never tested)
2. `power-management-minimal.nix` - Just NVIDIA optimizations (retest)
3. `power-management-ppd.nix` - Power Profiles Daemon (previous winner)
4. `power-management-tlp.nix` - TLP only (retest)
5. `power-management-auto-cpufreq.nix` - Auto CPU frequency
6. `power-management-system76.nix` - System76 power daemon
7. `power-management-powertop.nix` - Powertop only

## Monitoring Progress

Check the journal to see what's happening:
```bash
journalctl --user -u power-test.service -f
```

Check current state:
```bash
cat ~/.power-test-state.json
```

## Emergency Stop

If you need to stop the testing:
```bash
# Disable the service
systemctl --user disable power-test.service
systemctl --user stop power-test.service

# Remove state file
rm ~/.power-test-state.json

# IMPORTANT: Remove testing mode import from configuration.nix
# Then rebuild: cd ~/nixos-config && sudo nixos-rebuild switch --flake .#msi-laptop
```

## Notes

- Each test takes about 8-9 minutes (rebuild + settle + test)
- Total runtime: ~1 hour for all 7 configs
- Make sure laptop is plugged in or has enough battery
- Close all other applications before starting
- Don't use the laptop during testing for consistent results
