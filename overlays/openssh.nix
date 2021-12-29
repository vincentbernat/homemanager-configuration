self: super:
{
  openssh = super.openssh.overrideAttrs (old: {
    checkTarget = [];
    patches = (old.patches or []) ++ [
      (super.fetchpatch {
        url = "https://bugzilla.mindrot.org/attachment.cgi?id=3547";
        sha256 = "sha256-uF+pPRlO9UmavjqQox6RRGFKYrmxbqygXMr1Tx7J3mA=";
      })
    ];
  });
}
