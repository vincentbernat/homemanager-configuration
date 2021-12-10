self: super:
{
  # pipewire = super.pipewire.overrideAttrs (old: rec {
  #   # We need to keep the same version than in Debian.
  #   version = "0.3.32";
  #   src = super.fetchFromGitLab {
  #     domain = "gitlab.freedesktop.org";
  #     owner = "pipewire";
  #     repo = "pipewire";
  #     rev = version;
  #     sha256 = "0f5hkypiy1qjqj3frzz128668hzbi0fqmj0j21z7rp51y62dapnp";
  #   };
  #   # openaptx has been replaced by freeaptx in later versions
  #   buildInputs = old.buildInputs ++ [ super.libopenaptx ];
  # });
}
