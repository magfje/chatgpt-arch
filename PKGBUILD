pkgname=chatgpt-native-bin
pkgver=26.825.31414
pkgrel=1
pkgdesc="Official OpenAI ChatGPT desktop app, repackaged for Arch Linux"
arch=('x86_64' 'aarch64')
url="https://learn.chatgpt.com/docs/linux/linux-app"
license=('custom')
depends=(
  'alsa-lib'
  'at-spi2-core'
  'cairo'
  'dbus'
  'expat'
  'gcc-libs'
  'gdk-pixbuf2'
  'glib2'
  'glibc'
  'gtk3'
  'libcups'
  'libdrm'
  'libglvnd'
  'libnotify'
  'libusb'
  'libx11'
  'libxcb'
  'libxcomposite'
  'libxdamage'
  'libxext'
  'libxfixes'
  'libxkbcommon'
  'libxrandr'
  'mesa'
  'nspr'
  'nss'
  'pango'
  'systemd-libs'
  'vulkan-icd-loader'
  'xz'
  'xdg-utils'
)
optdepends=(
  'git: repository integration'
  'trash-cli: desktop trash integration'
  'vulkan-driver: hardware Vulkan implementation'
)
provides=("chatgpt=${pkgver}")
conflicts=('chatgpt')
options=('!debug' '!strip')

_repo_base='https://persistent.oaistatic.com/codex-app-prod/linux/deb'
_deb_path_x86_64='pool/main/c/chatgpt/chatgpt_26.825.31414_amd64.deb'
_deb_path_aarch64='pool/main/c/chatgpt/chatgpt_26.825.31414_arm64.deb'

source_x86_64=("chatgpt_${pkgver}_amd64.deb::${_repo_base}/${_deb_path_x86_64}")
source_aarch64=("chatgpt_${pkgver}_arm64.deb::${_repo_base}/${_deb_path_aarch64}")
sha256sums_x86_64=('c173048ba80f7af9cd8904f9a1f272aff4947a314f6fe97da1bb8368476cdcf9')
sha256sums_aarch64=('e2fbeab41cb06dfb08a84f270681a96dc5f32fe3f32cf3dec102129d34c9b6f8')

prepare() {
  local deb_arch

  case "$CARCH" in
    x86_64) deb_arch='amd64' ;;
    aarch64) deb_arch='arm64' ;;
    *) return 1 ;;
  esac

  rm -rf "$srcdir/deb-archive" "$srcdir/deb-root"
  mkdir -p "$srcdir/deb-archive" "$srcdir/deb-root"

  cd "$srcdir/deb-archive"
  ar x "$srcdir/chatgpt_${pkgver}_${deb_arch}.deb"

  local data_archive
  data_archive=$(find . -maxdepth 1 -type f -name 'data.tar.*' -print -quit)
  if [[ -z "$data_archive" ]]; then
    error 'The OpenAI package did not contain a data archive'
    return 1
  fi

  bsdtar -xf "$data_archive" -C "$srcdir/deb-root"
}

package() {
  cp -a "$srcdir/deb-root/." "$pkgdir/"

  # The Debian maintainer script conditionally disables this ABI-4.0 profile
  # on incompatible hosts. Arch does not run that script, and the profile is
  # unconfined, so omitting it is safer than installing a broken policy.
  rm -f "$pkgdir/etc/apparmor.d/chatgpt"
  rmdir --ignore-fail-on-non-empty "$pkgdir/etc/apparmor.d" "$pkgdir/etc" 2>/dev/null || true

  rm -rf "$pkgdir/usr/share/lintian"
  install -Dm644 \
    "$pkgdir/usr/share/doc/chatgpt/copyright" \
    "$pkgdir/usr/share/licenses/$pkgname/copyright"
}
