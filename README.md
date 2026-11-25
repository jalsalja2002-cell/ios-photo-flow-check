# iOS Photo Flow Check


A reusable Maestro example for checking a photo workflow after an iOS app update. It selects a test image, waits for a result, restarts the app with its data intact, and checks that the same result can be opened from the gallery.


## Try the included sample


Install Xcode with the iOS 27.0 simulator runtime, [Maestro](https://docs.maestro.dev/maestro-cli/how-to-install-maestro-cli), and Java 17 or later. From a local checkout, run:


```sh
bash run-sample.sh
```


The script builds the UIKit sample, creates a fresh iPhone 17 simulator, installs the sample, imports the supplied synthetic image, and runs the flow. The sample selects the first photo tile using the iOS 27 picker identifier and checks that the chosen image is 160 × 160, the supplied image's dimensions. It prints the report directory and removes the simulator it created on success. A failed run keeps that simulator and prints its ID for inspection.


Use `MAESTRO_BIN` if Maestro is outside your PATH. The supplied simulator defaults are iPhone 17 and iOS 27.0.


## Setup for your own app


- Use a Mac with Xcode, a booted iOS Simulator, and [Maestro](https://docs.maestro.dev/maestro-cli/how-to-install-maestro-cli).
- Install your app's simulator build. Use a test account or a stub backend that does not issue real charges.
- Put one synthetic or nonpersonal image in the simulator's photo library. Assign the app's accessibility identifiers to the IDs shown in the command below.
- Inspect the system picker with `maestro hierarchy`. Set `FIXTURE_SELECTOR` to an anchored Maestro text regular expression matching the full accessibility label of your fixture. Broad matches can select the photo grid container instead of a photo. If the picker exposes no unique text, replace the selector with a known accessibility ID or an index in an isolated test photo library. This example assumes a single-select picker that returns to the app on tap. A picker that needs a confirmation button requires an extra tap.
- Start with a clean test account or test data. `RESULT_ROW_ID` should uniquely identify the generated fixture result in the gallery. Configure your test build or stub to give this result a known ID. Each test run should start without a previous row with that ID, or it could reopen an older result.


## Run


From this repository's root:


```sh
maestro test \
  -e APP_ID=com.example.photoapp \
  -e PICK_PHOTO_ID=pick-photo \
  -e FIXTURE_SELECTOR='^Example fixture label$' \
  -e PREVIEW_ID=selected-photo-preview \
  -e GENERATE_ID=generate \
  -e GENERATED_RESULT_ID=generated-result \
  -e GALLERY_ID=open-gallery \
  -e RESULT_ROW_ID=gallery-result-test-fixture \
  -e REOPENED_RESULT_ID=reopened-result \
  flows/photo-result.yaml
```


The result screen selectors should be visible only after the corresponding image is ready. Adjust the 60-second wait to match your test backend.


If photo selection fails, inspect the picker permissions and accessibility tree on the same iOS version. Maestro documents [gallery selection](https://docs.maestro.dev/examples/recipes/choose-images-from-the-gallery), and [an iOS 26 picker issue](https://github.com/mobile-dev-inc/maestro-docs/issues/178) describes one reported failure.


## Verified run

On 2026-11-25, all seven files in a fresh GitHub ZIP matched the reviewed files byte for byte. Running the included `run-sample.sh` from that extracted copy created a new iPhone 17 simulator running iOS 27.0. Maestro 2.12.1 with Temurin Java 21.0.13.1 reported **1/1 flow passed in 21 seconds**. The reported flow time excludes the build and simulator boot.


In a separate run using an exact photo accessibility label, the flow passed all 11 actions in 19 seconds with Maestro 2.12.1 and Temurin Java 21.0.13.1 on an iPhone 17 simulator running iOS 27.0. The run used a local UIKit sample with a synthetic image and no backend. It selected the image in the system picker, generated and saved a local result, restarted the app, and opened the saved result.


To reproduce this on your app, map the identifiers in the command and inspect the full photo label on your own simulator. Replace the sample label with that exact label, escaping any regex metacharacters. The example checks visible app behavior. Pixel quality, backend persistence, and credit balances require separate checks.


## 한국어 안내


iOS 앱 업데이트 후 테스트 사진을 선택하고, 생성 결과를 확인한 뒤, 앱을 재시작해 사진함에서 다시 열리는지 점검하는 예제입니다. 샘플 식별자를 자신의 앱에 맞게 바꾸고, 비용이 청구되지 않는 테스트 환경에서 실행하세요. 반복 실행할 때는 이전 결과를 비우거나 실행마다 고유한 결과 행 식별자를 사용하세요. GitHub ZIP에서 새로 풀어 실행한 샘플이 iPhone 17 시뮬레이터(iOS 27.0)에서 21초에 통과했습니다.


MIT licensed.
