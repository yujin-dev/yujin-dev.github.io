---
title: "Pull Request"
category: "dev"
---

pullRequest는 work branch에서 작업한 코드를 merge 이전에 검사를 자동화할 수 있는 기능이 많다. 
빌드-테스트를 자동으로 실행할 수 있는 점은 CI 관점에서 이점이 있다.

Jenkins의 Github Pull Request Builder을 활용하여 work branch의 빌드 상태를 검사할 수 있다.

즉, Jenkins의 `Github Pull Request Builder` 플러그인과 Github `Webhook`을 이용하여 Pull Request를 하면 자동으로 빌드 환경을 구축하면 된다.

1. Github - Jenkins 연동
    - Jenkins에서 Github 코드를 받아 빌드하여 결과를 리포트한다.
    - 인증 토큰을 설정하기 위해 Github의 Personal access tokens을 저장해둔다.
2. Jenkins에서 Github Pull Request Builder 설정
    - pluginManager에서 해당 플러그인을 설치한다.
3. Jenkins에서 Build Job을 설정한다.
    - Jenkins job에서 GitHub Pull Request Builder 플러그인으로 빌드를 유발시킨다.
    - Github에서 Repository Webhook이 자동으로 설정된다.
4. Github에서 Branch protection rules를 설정한다.
    - 빌드가 실패하면 merge를 하지 못하도록 방지한다.

이외 [github actions](https://rdd9223.github.io/github%20action/Github_Action/)을 통해 테스트를 자동화할 수 있다.

gitlab과 연동하기 위해서는 https://dejavuqa.tistory.com/143에서 참고한다.

*[출처]*
- https://taetaetae.github.io/2020/09/07/github-pullrequest-build/
- https://forl.tistory.com/139

*[참고]*
- https://velog.io/@whdgh0331/vagrant-%EC%97%90%EC%84%9C-Jenkins-%EC%99%80-git-push-git-pull-request-builder-%EC%A0%81%EC%9A%A9-5ck3pmigy3