#!/usr/bin/env bash
# Build vendor/ from the TrustBuilder application that is installed on THIS machine.
#
# vendor/ holds inWebo's own client library (neon-lib-js, iw-commons-js) and its
# dependencies. That code is proprietary and it is not on public npm, so this
# repository does not contain it. Every user extracts it from their own licensed
# copy of Authenticator 6.
#
# Run this one time, before the first use:
#   ./scripts/extract-vendor.sh
#
# Set TB_ASAR to give the path to app.asar if the search does not find it.
set -euo pipefail

here=$(cd -- "$(dirname -- "$0")/.." && pwd)
dst=$here/vendor

msg() { printf '\033[36m==>\033[0m %s\n' "$*"; }
die() {
  echo "extract-vendor: $*" >&2
  exit 1
}

command -v node >/dev/null 2>&1 || die "node is not on PATH"

# 1. Find app.asar.
asar=${TB_ASAR:-}
if [ -z "$asar" ]; then
  for c in \
    /nix/store/*-trustbuilder-*-extracted/resources/app.asar \
    /opt/*uthenticator*/resources/app.asar \
    /opt/TrustBuilder*/resources/app.asar \
    /usr/lib/*uthenticator*/resources/app.asar \
    "$HOME"/.local/share/*uthenticator*/resources/app.asar; do
    [ -f "$c" ] || continue
    asar=$c
    break
  done
fi
[ -n "$asar" ] || die "app.asar not found. Install Authenticator 6, or set TB_ASAR=<path>."
msg "asar: $asar"

# 2. Unpack it. The asar header is a 16-byte prefix, then a JSON directory.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
node -e '
const fs=require("fs"),path=require("path");
const [src,dst]=process.argv.slice(1);
const buf=fs.readFileSync(src);
const jlen=buf.readUInt32LE(12);
const hdr=JSON.parse(buf.slice(16,16+jlen).toString("utf8"));
const dataOff=8+buf.readUInt32LE(4);
(function walk(node,rel){
  for(const [name,v] of Object.entries(node.files||{})){
    const p=path.join(rel,name);
    if(v.files){fs.mkdirSync(path.join(dst,p),{recursive:true});walk(v,p);}
    else if(v.offset!==undefined){
      fs.mkdirSync(path.join(dst,rel),{recursive:true});
      const o=dataOff+Number(v.offset);
      fs.writeFileSync(path.join(dst,p),buf.slice(o,o+v.size));
    }
  }
})(hdr,"");
' "$asar" "$tmp"
src=$tmp/node_modules
[ -d "$src/neon-lib-js" ] || die "no neon-lib-js inside $asar"

# 3. Copy the two inWebo packages, then resolve the rest by trial.
#    A loop is used because the dependency set changes between app versions.
msg "copy into $dst"
rm -rf "$dst"
mkdir -p "$dst"
# Do this now, not at the end. Node finds a dependency by a walk up from the real
# path of the package, so vendor/ is only searchable once node_modules points at it.
# The resolve loop below depends on that.
ln -sfn vendor "$here/node_modules"
for d in neon-lib-js iw-commons-js; do
  cp -r "$src/$d" "$dst/"
done

for _ in $(seq 1 40); do
  missing=$(node -e 'require("'"$dst"'/neon-lib-js")' 2>&1 |
    grep -oP "Cannot find module '\K[^']+" | head -1 || true)
  [ -n "$missing" ] || break
  # A require can name a file inside a package, so keep only the package name.
  case $missing in
  @*) pkg=$(echo "$missing" | cut -d/ -f1,2) ;;
  *) pkg=${missing%%/*} ;;
  esac
  [ -e "$src/$pkg" ] || die "the asar does not contain the package '$pkg'"
  [ -e "$dst/$pkg" ] && die "no progress: '$pkg' is copied but node does not find it"
  echo "    + $pkg"
  mkdir -p "$dst/$(dirname "$pkg")"
  cp -r "$src/$pkg" "$dst/$pkg"
done

chmod -R u+w "$dst"
node -e 'const M=require("'"$dst"'/neon-lib-js");console.log("neon-lib-js "+M.IW.LIB_VERSION+" loads")' ||
  die "vendor/ is incomplete"

msg "done. $(du -sh "$dst" | cut -f1) in $dst"
