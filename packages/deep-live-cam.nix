{ pkgs, ... }:

pkgs.writeShellScriptBin "deep-live-cam" ''
  export PATH="${pkgs.podman}/bin:$PATH"
  CONTAINER="deep-live-cam"
  INSTALL_DIR="$HOME/.local/share/deep-live-cam"

  if ! ${pkgs.distrobox}/bin/distrobox list | grep -q "| $CONTAINER"; then
    echo "Creating $CONTAINER distrobox (first run, requires NVIDIA GPU)..."
    ${pkgs.distrobox}/bin/distrobox create \
      --name "$CONTAINER" \
      --image ubuntu:22.04 \
      --nvidia \
      --additional-flags "--device nvidia.com/gpu=all" \
      --yes
  fi

  # Install deps and clone repo on first run (sentinel: .installed file written on success)
  if ! ${pkgs.distrobox}/bin/distrobox enter "$CONTAINER" -- test -f "$INSTALL_DIR/.installed"; then
    echo "Setting up Deep-Live-Cam (first run, this will take a while)..."
    ${pkgs.distrobox}/bin/distrobox enter "$CONTAINER" -- bash -c '
      set -e
      rm -rf "'"$INSTALL_DIR"'"
      sudo apt-get update -qq
      sudo apt-get install -y -qq \
        python3.11 python3.11-venv python3.11-dev python3.11-tk \
        python3-pip git ffmpeg libgl1 libglib2.0-0

      git clone https://github.com/hacksider/Deep-Live-Cam "'"$INSTALL_DIR"'"
      cd "'"$INSTALL_DIR"'"

      python3.11 -m venv venv
      source venv/bin/activate
      pip install --quiet --upgrade pip
      pip install --quiet torch torchvision --index-url https://download.pytorch.org/whl/cu121
      pip install --quiet -r requirements.txt
      touch .installed
    '
  fi

  exec ${pkgs.distrobox}/bin/distrobox enter "$CONTAINER" -- \
    bash -c 'cd "'"$INSTALL_DIR"'" && source venv/bin/activate && python3 run.py --execution-provider cuda "$@"' _ "$@"
''
