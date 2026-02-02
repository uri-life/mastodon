#!/bin/sh
# 변경된 버전 감지 및 필터링 스크립트
# 사용: scripts/detect-versions.sh <env_file>

set -e

ENV_FILE="${1:-.ci.env}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 버전 유틸리티 로드
. "$SCRIPT_DIR/version-utils.sh"

# 환경 파일 초기화
touch "$ENV_FILE"

# 변경된 파일에서 버전 추출 (현재 커밋의 변경사항)
echo "=== 변경된 파일 감지 ==="

# 디버깅 정보
echo "디버그: HEAD=$(git rev-parse HEAD 2>/dev/null || echo '없음')"
echo "디버그: git log"
git log --oneline -3 2>/dev/null || echo "(git log 실패)"

# git show로 현재 커밋의 변경 파일 감지 (depth >= 2 필요)
echo "방법: git show HEAD"
CHANGED_FILES=$(git show --name-only --format="" HEAD 2>/dev/null || true)

# 대체: git diff HEAD~1 (git show가 실패할 경우)
if [ -z "$CHANGED_FILES" ]; then
  echo "방법: git diff HEAD~1"
  CHANGED_FILES=$(git diff --name-only HEAD~1 HEAD 2>/dev/null || true)
fi

if [ -z "$CHANGED_FILES" ]; then
  echo "경고: 변경된 파일을 감지할 수 없음"
fi

echo "디버그: 감지된 파일 수=$(echo "$CHANGED_FILES" | grep -c . || echo 0)"
echo "$CHANGED_FILES"

# versions/vX.Y.Z/patches/uriX.Y 패턴 추출
CHANGED_VERSIONS=$(echo "$CHANGED_FILES" | grep -oE 'versions/v[0-9]+\.[0-9]+\.[0-9]+/patches/uri[0-9]+\.[0-9]+' | sort -u || true)

if [ -z "$CHANGED_VERSIONS" ]; then
  echo "빌드할 버전이 없습니다."
  echo "VERSIONS_TO_BUILD=" >> "$ENV_FILE"

  # 최신 버전은 여전히 계산
  echo "=== 최신 버전 판단 ==="
  ALL_VERSIONS=$(find versions -mindepth 3 -maxdepth 3 -type d -path "*/patches/uri*" | \
    sed -E 's|versions/(v[0-9]+\.[0-9]+\.[0-9]+)/patches/(uri[0-9]+\.[0-9]+)|\1:\2|' | sort -u)

  if [ -z "$ALL_VERSIONS" ]; then
    echo "경고: 버전 디렉토리를 찾을 수 없습니다."
    echo "LATEST_VERSION=" >> "$ENV_FILE"
  else
    LATEST_MASTODON=$(echo "$ALL_VERSIONS" | cut -d: -f1 | sort -V | tail -1)
    LATEST_URI=$(echo "$ALL_VERSIONS" | grep "^${LATEST_MASTODON}:" | cut -d: -f2 | sort -t. -k1,1n -k2,2n | tail -1)
    LATEST_VERSION="${LATEST_MASTODON}:${LATEST_URI}"
    echo "최신 버전: $LATEST_VERSION"
    echo "LATEST_VERSION=$LATEST_VERSION" >> "$ENV_FILE"
  fi

  cat "$ENV_FILE"
  exit 0
fi

echo "=== 변경된 버전 ==="
echo "$CHANGED_VERSIONS"

echo "=== 최소 요구 버전: ${MIN_MASTODON_VERSION}+${MIN_URI_VERSION} 초과 ==="

# 버전 조합 추출 (형식: vX.Y.Z:uriX.Y) - 최소 버전보다 높은 것만
VERSIONS_TO_BUILD=""
for path in $CHANGED_VERSIONS; do
  MASTODON_VER=$(echo "$path" | sed -E 's|versions/(v[0-9]+\.[0-9]+\.[0-9]+)/patches/.*|\1|')
  URI_VER=$(echo "$path" | sed -E 's|versions/v[0-9]+\.[0-9]+\.[0-9]+/patches/(uri[0-9]+\.[0-9]+)|\1|')

  if is_version_above_minimum "$MASTODON_VER" "$URI_VER"; then
    echo "  ✓ ${MASTODON_VER}+${URI_VER}: 빌드 대상"
    VERSION_COMBO="${MASTODON_VER}:${URI_VER}"
    if [ -z "$VERSIONS_TO_BUILD" ]; then
      VERSIONS_TO_BUILD="$VERSION_COMBO"
    else
      VERSIONS_TO_BUILD="$VERSIONS_TO_BUILD $VERSION_COMBO"
    fi
  else
    echo "  ✗ ${MASTODON_VER}+${URI_VER}: 최소 버전 미달, 스킵"
  fi
done

echo "VERSIONS_TO_BUILD=$VERSIONS_TO_BUILD" >> "$ENV_FILE"

# 최신 버전 판단: 전체 버전 목록에서 가장 높은 vX.Y.Z + 가장 높은 uriX.Y
echo "=== 최신 버전 판단 ==="
ALL_VERSIONS=$(find versions -mindepth 3 -maxdepth 3 -type d -path "*/patches/uri*" | \
  sed -E 's|versions/(v[0-9]+\.[0-9]+\.[0-9]+)/patches/(uri[0-9]+\.[0-9]+)|\1:\2|' | sort -u)

if [ -z "$ALL_VERSIONS" ]; then
  echo "경고: 버전 디렉토리를 찾을 수 없습니다."
  echo "LATEST_VERSION=" >> "$ENV_FILE"
else
  # vX.Y.Z 기준 정렬 후 최신 선택
  LATEST_MASTODON=$(echo "$ALL_VERSIONS" | cut -d: -f1 | sort -V | tail -1)

  # 해당 Mastodon 버전에서 가장 높은 uriX.Y 선택
  LATEST_URI=$(echo "$ALL_VERSIONS" | grep "^${LATEST_MASTODON}:" | cut -d: -f2 | sort -t. -k1,1n -k2,2n | tail -1)

  LATEST_VERSION="${LATEST_MASTODON}:${LATEST_URI}"
  echo "최신 버전: $LATEST_VERSION"
  echo "LATEST_VERSION=$LATEST_VERSION" >> "$ENV_FILE"
fi

if [ -z "$VERSIONS_TO_BUILD" ]; then
  echo "빌드할 버전이 없습니다. (모두 최소 버전 미달)"
fi

cat "$ENV_FILE"
