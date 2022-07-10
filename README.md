# Nix configuration (used with Debian)

This is my configuration for [home-manager][]. I am using it on top of
Debian Sid for stuff where Nix is better:

 - packages not present in Debian
 - packages too outdated in Debian
 - need to patch the package

For a complete picture on the integration with Debian, also have a
look at my [.zshenv][]. There is also a hack to make libXcursor works
as expected. Check my [.xsession][] and [.Xresources][].

[home-manager]: https://nix-community.github.io/home-manager/
[.zshenv]: https://github.com/vincentbernat/zshrc/blob/master/zshenv
[.xsession]: https://github.com/vincentbernat/i3wm-configuration/blob/master/dotfiles/xsession
[.Xresources]: https://github.com/vincentbernat/i3wm-configuration/blob/master/dotfiles/Xresources

I am relying on flakes only, not channels. To install home-manager,
the steps are something like this:

- enable flakes and the new nix command in `~/.config/nix/nix.conf`
  with `experimental-features = nix-command flakes`
- check where the nix command is installed (`readlink -f =nix`)
- uninstall everything from nix-env (`nix-env -u`)
- remove all channels with `nix-channel --remove`
- install home-manager with `PATH=/nix/store/...:$PATH nix run github:nix-community/home-manager switch`
