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

# 태그 이벤트인 경우: CI_COMMIT_TAG에서 버전 추출 (vX.Y.Z+uriX.Y 형식)
if [ -n "$CI_COMMIT_TAG" ]; then
  # 태그 형식 검증: vX.Y.Z+uriX.Y (중간에 추가 문자 허용)
  if echo "$CI_COMMIT_TAG" | grep -qE '^v[0-9]+\.[0-9]+\.[0-9]+.*\+uri[0-9]+\.[0-9]+$'; then
    # vX.Y.Z 추출 (+ 앞부분에서 v로 시작하는 버전)
    MASTODON_VER=$(echo "$CI_COMMIT_TAG" | sed -E 's/^(v[0-9]+\.[0-9]+\.[0-9]+).*\+uri.*/\1/')
    # uriX.Y 추출 (+ 뒷부분)
    URI_VER=$(echo "$CI_COMMIT_TAG" | sed -E 's/.*\+(uri[0-9]+\.[0-9]+)$/\1/')

    # 패치 디렉토리 존재 확인
    PATCH_DIR="versions/${MASTODON_VER}/patches/${URI_VER}"
    if [ -d "$PATCH_DIR" ]; then
      VERSION_COMBO="${MASTODON_VER}:${URI_VER}"
      echo "VERSIONS_TO_BUILD=$VERSION_COMBO" >> "$ENV_FILE"
      echo "LATEST_VERSION=$VERSION_COMBO" >> "$ENV_FILE"
      echo "태그에서 버전 감지: $VERSION_COMBO"
      exit 0
    else
      echo "ERROR: 태그에 해당하는 패치 디렉토리가 없습니다: $PATCH_DIR"
      exit 1
    fi
  else
    echo "ERROR: 태그 형식이 올바르지 않습니다: $CI_COMMIT_TAG (예상: vX.Y.Z+uriX.Y)"
    exit 1
  fi
fi

# 변경된 파일에서 버전 추출 (현재 커밋의 변경사항)
# git show로 현재 커밋의 변경 파일 감지 (depth >= 2 필요)
CHANGED_FILES=$(git show --name-only --format="" HEAD 2>/dev/null || true)

# 대체: git diff HEAD~1 (git show가 실패할 경우)
if [ -z "$CHANGED_FILES" ]; then
  CHANGED_FILES=$(git diff --name-only HEAD~1 HEAD 2>/dev/null || true)
fi

# versions/vX.Y.Z/patches/uriX.Y 패턴 추출
CHANGED_VERSIONS=$(echo "$CHANGED_FILES" | grep -oE 'versions/v[0-9]+\.[0-9]+\.[0-9]+/patches/uri[0-9]+\.[0-9]+' | sort -u || true)

if [ -z "$CHANGED_VERSIONS" ]; then
  echo "VERSIONS_TO_BUILD=" >> "$ENV_FILE"

  # 최신 버전은 여전히 계산
  ALL_VERSIONS=$(find versions -mindepth 3 -maxdepth 3 -type d -path "*/patches/uri*" | \
    sed -E 's|versions/(v[0-9]+\.[0-9]+\.[0-9]+)/patches/(uri[0-9]+\.[0-9]+)|\1:\2|' | sort -u)

  if [ -z "$ALL_VERSIONS" ]; then
    echo "LATEST_VERSION=" >> "$ENV_FILE"
  else
    LATEST_MASTODON=$(echo "$ALL_VERSIONS" | cut -d: -f1 | sort -V | tail -1)
    LATEST_URI=$(echo "$ALL_VERSIONS" | grep "^${LATEST_MASTODON}:" | cut -d: -f2 | sort -t. -k1,1n -k2,2n | tail -1)
    LATEST_VERSION="${LATEST_MASTODON}:${LATEST_URI}"
    echo "LATEST_VERSION=$LATEST_VERSION" >> "$ENV_FILE"
  fi
  exit 0
fi

# 버전 조합 추출 (형식: vX.Y.Z:uriX.Y) - 최소 버전보다 높은 것만
VERSIONS_TO_BUILD=""
for path in $CHANGED_VERSIONS; do
  MASTODON_VER=$(echo "$path" | sed -E 's|versions/(v[0-9]+\.[0-9]+\.[0-9]+)/patches/.*|\1|')
  URI_VER=$(echo "$path" | sed -E 's|versions/v[0-9]+\.[0-9]+\.[0-9]+/patches/(uri[0-9]+\.[0-9]+)|\1|')

  if is_version_above_minimum "$MASTODON_VER" "$URI_VER"; then
    VERSION_COMBO="${MASTODON_VER}:${URI_VER}"
    if [ -z "$VERSIONS_TO_BUILD" ]; then
      VERSIONS_TO_BUILD="$VERSION_COMBO"
    else
      VERSIONS_TO_BUILD="$VERSIONS_TO_BUILD $VERSION_COMBO"
    fi
  fi
done

echo "VERSIONS_TO_BUILD=$VERSIONS_TO_BUILD" >> "$ENV_FILE"

# 최신 버전 판단: 전체 버전 목록에서 가장 높은 vX.Y.Z + 가장 높은 uriX.Y
ALL_VERSIONS=$(find versions -mindepth 3 -maxdepth 3 -type d -path "*/patches/uri*" | \
  sed -E 's|versions/(v[0-9]+\.[0-9]+\.[0-9]+)/patches/(uri[0-9]+\.[0-9]+)|\1:\2|' | sort -u)

if [ -z "$ALL_VERSIONS" ]; then
  echo "LATEST_VERSION=" >> "$ENV_FILE"
else
  # vX.Y.Z 기준 정렬 후 최신 선택
  LATEST_MASTODON=$(echo "$ALL_VERSIONS" | cut -d: -f1 | sort -V | tail -1)

  # 해당 Mastodon 버전에서 가장 높은 uriX.Y 선택
  LATEST_URI=$(echo "$ALL_VERSIONS" | grep "^${LATEST_MASTODON}:" | cut -d: -f2 | sort -t. -k1,1n -k2,2n | tail -1)

  LATEST_VERSION="${LATEST_MASTODON}:${LATEST_URI}"
  echo "LATEST_VERSION=$LATEST_VERSION" >> "$ENV_FILE"
fi
