self: super:
{
  goaccess = super.goaccess.overrideAttrs (old: {
    patches = (old.patches or []) ++ [
      (super.fetchpatch {
        url = "https://github.com/allinurl/goaccess/pull/2126.patch";
        sha256 = "sha256-Csb9ooM933m3bcx61LEx+VkmnfzajOMUnAhkcnDPgv4=";
      })
    ];
  });
}
