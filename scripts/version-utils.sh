#!/bin/sh
# 버전 비교 유틸리티 함수
# 사용: source scripts/version-utils.sh

# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <https://unlicense.org/>

# 최소 요구 버전
MIN_MASTODON_VERSION='v4.4.12'
MIN_URI_VERSION='uri2.11'

# 버전 비교 함수: version_gt $1 $2 → $1 > $2 이면 0 반환
version_gt() {
  [ "$(printf '%s\n' "$1" "$2" | sort -V | tail -1)" = "$1" ] && [ "$1" != "$2" ]
}

# 버전 비교 함수: version_ge $1 $2 → $1 >= $2 이면 0 반환
version_ge() {
  [ "$(printf '%s\n' "$1" "$2" | sort -V | tail -1)" = "$1" ]
}

# 버전이 최소 요구사항보다 높은지 확인
# 조건: Mastodon >= min AND URI >= min AND (Mastodon > min OR URI > min)
# $1: mastodon version (vX.Y.Z)
# $2: uri version (uriX.Y)
is_version_above_minimum() {
  local mver="$1"
  local uver="$2"

  # 두 버전 모두 최소 이상이어야 함
  if ! version_ge "$mver" "$MIN_MASTODON_VERSION"; then
    return 1
  fi
  if ! version_ge "$uver" "$MIN_URI_VERSION"; then
    return 1
  fi

  # 적어도 하나는 초과해야 함
  if version_gt "$mver" "$MIN_MASTODON_VERSION" || version_gt "$uver" "$MIN_URI_VERSION"; then
    return 0
  fi

  # 둘 다 같으면 실패
  return 1
}
