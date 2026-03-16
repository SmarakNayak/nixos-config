# Uses docker/podman-compose because facefusion runs a web UI (Gradio on
# localhost:7870) — files are uploaded through the browser, so the container
# doesn't need access to the host filesystem.
{ pkgs, ... }:

pkgs.writeShellScriptBin "facefusion" ''
  export PATH="${pkgs.podman}/bin:${pkgs.podman-compose}/bin:$PATH"
  INSTALL_DIR="$HOME/.local/share/facefusion-docker"

  if [ ! -d "$INSTALL_DIR" ]; then
    echo "Cloning facefusion-docker (first run)..."
    ${pkgs.git}/bin/git clone https://github.com/facefusion/facefusion-docker "$INSTALL_DIR"
  fi

  cd "$INSTALL_DIR"
  echo "Starting facefusion... Web UI will be available at http://localhost:7870"
  exec ${pkgs.podman-compose}/bin/podman-compose -f docker-compose.cuda.yml up
''
