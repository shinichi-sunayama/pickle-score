# pickle-score — Claude 向けメモ

ピックルボールのサーブ前のコール（例 4-2-1）をボタンだけで数えるアプリ。おはぎきなこ工房の作品（チワちくシリーズとは別）。

## ユーザーについて
- 個人開発者。ピックルボール初心者。返答はすべて日本語、専門用語は短い説明つき。コード・コミットは英語でよい。
- 予算 $0。GitHub Actions の macOS 無料枠は全作品で共有なので使わない（Linux は公開リポジトリなら無料）。

## 構成
- `web/core.js` … 数え方のルール（画面なし・純粋な関数）。ルール変更はここだけ。
- `web/app.js` `web/index.html` `web/style.css` … 画面（見た目はほえほえチワ隊に寄せる：M PLUS Rounded、クリーム＋空色、ふちのある立体ボタン）。
- `web/voice.js` `web/voice-words.json` … 読み上げ。数字は英語（0＝ゼロ）。VOICEVOX の声は `web/voices/<id>/*.wav` と `voices.json`（`tools/make_voices.py` で作成、PC で VOICEVOX を起動しておく）。規約とクレジットは `docs/voices.md`。
- `web/fonts/` … 文字を減らしたフォント。**画面に新しい日本語を足したら `tools/make_font.py` を実行し直す**（元フォントは chiwa-survivor の `Assets/_Game/Resources/Fonts/MPLUSRounded1c-Bold.ttf`）。
- `web/history.js` … 試合の履歴（純粋な関数・テストあり）。`web/img/dogs/` … 犬の絵（`tools/import_dogs.py`）。犬は勝った画面・サーブのしるし・設定の下だけ。
- `web/sw.js` … オフライン用。**ファイルを変えたら `CACHE_NAME`（sw.js）と `APP_VERSION`（app.js）を一緒に上げる。** sw.js の FILES に新しいファイルを足すのも忘れない。
- `tests/cases.json` … ルールの具体例（手計算の期待値）。Web と将来の Swift で共通。
- `tests/core.test.js` … テスト本体。ブラウザなら `tests/index.html`、Node なら `node tests/run-node.mjs`。
- `tools/make_icons.py` … アイコン作成（Pillow）。`tools/make_font.py` と `tools/make_voices.py` は fonttools・brotli／VOICEVOX が必要。
- `docs/rules.md`（出典）、`docs/decisions.md`（決定ログ）、`docs/mac-setup.md`（B の準備）、`docs/asset-licenses.md`（素材の条件）、`docs/art/icon.md`（Gemini 用アイコンの指示文）。

## iPhone＋Apple Watch 版（`apple/`、Mac なしで作る）
- `apple/PickleCore/` … 数え方・履歴・読み上げの言葉の Swift 版（web/core.js・history.js の移植）。テストは `tests/cases.json` を共有し、GitHub の Linux で `swift test`（pages.yml の swift-core）。**ルールを変えたら JS と Swift の両方を直す。**
- `apple/project.yml` … XcodeGen の設定（Xcode プロジェクトは作るたびに生成、git に入れない）。`apple/iOS`・`apple/Watch`・共通の `apple/Shared`。声は `web/voices`、犬とアイコンは `tools/make_apple_assets.sh` が `apple/Generated/` に作る。
- `.github/workflows/apple.yml` … クラウドの Mac（公開リポジトリなので無料）で組み立て。`apple/` を push すると署名なしで組み立て確認、`gh workflow run apple.yml -f upload=true` で署名して TestFlight へ。手順は `docs/ios-testflight.md`。
- バンドル ID：`com.ohagikinakokobo.picklecall`（iPhone）・`com.ohagikinakokobo.picklecall.watchkitapp`（Watch）。フォントの PostScript 名は `RoundedMplus1c-Bold`。

## 動かし方（Windows）
- この PC には Node がない。`.claude/launch.json` の `pickle-score`（python http.server、ポート 8123）で開き、
  画面は `/web/index.html`、テストは `/tests/index.html`。
- push すると GitHub Actions が Node でテストし、通れば `web/` を GitHub Pages に公開する。

## 公開
- https://shinichi-sunayama.github.io/pickle-score/ （リポジトリ shinichi-sunayama/pickle-score、公開）
- App Store（1.0.0、2026-11-16 公開、無料、iPhone＋Watch）：https://apps.apple.com/jp/app/id6835014633 。次の更新は 1.1（候補：iPhone と Watch の履歴の同期）。
- `shinichi-sunayama.github.io` リポジトリ（app-ads.txt・工房サイト）には絶対にさわらない。

## 守ること
- 外部サービス・解析・広告なし。データは端末内の localStorage だけ。
- ルールを変えるときは、まず `tests/cases.json` に手計算の例を足してから `core.js` を直す。
- 決めたことは `docs/decisions.md` に追記する。
