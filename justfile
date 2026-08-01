default:
    @just --list

# Build and launch the packaged shell.
run:
    nix run "{{justfile_directory()}}"

# Launch the source tree through the flake development environment.
dev:
    nix develop "{{justfile_directory()}}" --command qs -p "{{justfile_directory()}}"
