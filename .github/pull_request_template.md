## 🎫 관련 이슈 (Linked Issues)
Closes #

## 🛠 작업 내용 (What I did)
- 프로필 이미지 선택을 위한 `ImagePicker` 컴포넌트 구현
- `PermissionManager`를 도입하여 갤러리 접근 권한 로직 분리
- 이미지 업로드 API (`POST /api/user/profile`) 연동 완료

## 💻 구현 상세 (Implementation Details)
- 기존에는 `UIImagePickerController`를 사용했으나, 다중 선택 확장을 고려해 `PHPickerViewController`로 변경했습니다.
- 이미지는 로컬에서 압축 후 전송하도록 로직을 추가했습니다.

## 📸 스크린샷 (Screenshots)
|기능 실행 전|기능 실행 후|
|:---:|:---:|
|![Before](...)|![After](...)|

## 🧐 리뷰 포인트 (Review Points)
- `ImagePicker`의 메모리 해제 처리가 올바르게 되었는지 확인 부탁드립니다.
- 권한 거부 시 노출되는 알림 팝업 문구가 적절한지 봐주세요.

## ✅ 자가 점검 (Self Checklist)
- [ ] 빌드 및 테스트가 정상적으로 통과되었나요?
- [ ] 관련 이슈 번호를 정확히 기재했나요? (Closes #...)
- [ ] 불필요한 주석이나 디버그 코드를 삭제했나요?
