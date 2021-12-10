self: super:
{
  gtk4 = super.gtk4.overrideAttrs (old: {
    patches = (old.patches or []) ++ [
      (super.fetchpatch {
        url = "https://gitlab.gnome.org/GNOME/gtk/-/merge_requests/3806.patch";
        sha256 = "1pj85qkh9i9fmgr6rnzyh5vqii9j62mi6rn480fi26nci71qq18d";
      })
      (super.fetchpatch {
        url = "https://gitlab.gnome.org/GNOME/gtk/-/merge_requests/3808.patch";
        sha256 = "0rzzvzxg1l2ppkvdknsyjql5p69929d2zq53z0mwbs5hlnwyrnsg";
      })
    ];
  });
}
