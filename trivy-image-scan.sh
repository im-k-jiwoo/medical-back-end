#!/bin/bash
## Docker 이미지 이름
dockerImageName=$(awk 'NR==1 {print $2}' Dockerfile)
echo $dockerImageName

## Trivy 이미지 스캔 실행
# -v $WORKSPACE:/root/.cache/: Trivy 캐시를 Jenkins 워크스페이스로 캐시 공유
# -q: Trivy의 출력 간소화
# --exit-code 1: 취약점이 발견되면 'exit_code' 1 반환
# --severity CRITICAL: 심각도가 CRITICAL인 취약점만 보고
# --light: 가볍게 스캔, 패키지 버전만 확인
docker run --rm -v $WORKSPACE:/root/.cache/ -e 
TRIVY_GITHUB_TOKEN="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" 
aquasec/trivy:0.17.2 -q image --exit-code 1 
--severity CRITICAL --light $dockerImageName

## Trivy 스캔 결과 처리
exit_code=$?
echo "종료 코드: $exit_code"
#
## 스캔 결과 확인
if [[ "$exit_code" == 1 ]]; then
    echo "이미지 스캔에 실패했습니다. CRITICAL 취약점이 발견되었습니다."
    exit 1
else
    echo "이미지 검사가 통과되었습니다. CRITICAL 취약점이 발견되지 않았습니다."
fi




