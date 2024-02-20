## Docker 이미지 이름
dockerImageName="medicine/back:latest"

## Trivy 이미지 스캔 실행
docker run --rm -v $WORKSPACE:/root/.cache/ -e TRIVY_GITHUB_TOKEN="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" aquasec/trivy:0.17.2 -q image --exit-code 1 --severity CRITICAL --light $dockerImageName

## Trivy 스캔 결과 처리
exit_code=$?
echo "종료 코드: $exit_code"
#
## 스캔 결과 확인
if [[ "$exit_code" == 1 ]]; then
    echo "이미지 스캔에 실패했습니다. 심각한 취약점이 발견되었습니다."
    exit 1
else
    echo "이미지 검사가 통과되었습니다. 심각한 취약점이 발견되지 않았습니다."
fi
