# 우리.인생 (uri.life)

[![status-badge](https://woodpeckerci.minacle.dev/api/badges/1/status.svg)](https://woodpeckerci.minacle.dev/repos/1)

Mastodon 기반의 소셜 네트워크 서비스인 [우리.인생 (uri.life)](https://uri.life/)의 수정 사항을 모아놓은 저장소입니다.

## 사용법

이 저장소는 [URI](https://github.com/uri-life/uri) 패치 관리 도구를 사용하여 적용할 수 있습니다.

1. 이 저장소를 클론합니다. `mastodon` 이외의 다른 디렉토리 이름을 사용하는 것을 권장합니다.

   ```sh
   git clone https://github.com/uri-life/mastodon.git uri-patches
   ```

2. [URI](https://github.com/uri-life/uri) 패치 관리 도구 저장소를 클론합니다.

   ```sh
   git clone https://github.com/uri-life/uri.git
   ```

3. [/manifest.yaml](manifest.yaml) 파일을 참조하여, 일치하는 Mastodon 저장소를 클론합니다. `https://github.com/mastodon/mastodon.git`을 예시로 사용합니다.

   ```sh
    git clone https://github.com/mastodon/mastodon.git mastodon
    ```

4. 이 저장소를 클론한 디렉토리로 이동합니다.

   ```sh
   cd uri-patches
   ```

5. URI 패치 관리 도구를 사용하여 원하는 버전에 원하는 패치를 적용합니다. 예를 들어, Mastodon v4.4.13에 uri2.13 패치를 적용하려면 다음과 같이 실행합니다.

   ```sh
   ../uri/bin/uri apply v4.4.13 uri2.13 ../mastodon
   ```

## 라이선스

확장자가 `.patch`인 모든 파일과, `/manifest.yaml` 및 `/versions/**/manifest.yaml` 파일은 [GNU Affero General Public License v3.0](https://www.gnu.org/licenses/agpl-3.0.html) 라이선스에 따라 배포됩니다. [LICENSE](LICENSE) 파일을 참조하세요.

그 외 모든 파일은 [The Unlicense](https://unlicense.org/) 라이선스에 따라 배포됩니다. 각 파일의 라이선스는 해당 파일의 헤더 주석에 명시되어 있습니다.
