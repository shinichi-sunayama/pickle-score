# pickle-score — Claude 向けメモ

ピックルボールのサーブ前のコール（例 4-2-1）をボタンだけで数えるアプリ。おはぎきなこ工房の作品（チワちくシリーズとは別）。

## ユーザーについて
- 個人開発者。ピックルボール初心者。返答はすべて日本語、専門用語は短い説明つき。コード・コミットは英語でよい。
- 予算 $0。GitHub Actions の macOS 無料枠は全作品で共有なので使わない（Linux は公開リポジトリなら無料）。

## 構成
- `web/core.js` … 数え方のルール（画面なし・純粋な関数）。ルール変更はここだけ。
- `web/app.js` `web/index.html` `web/style.css` … 画面。
- `web/sw.js` … オフライン用。**ファイルを変えたら `CACHE_NAME`（sw.js）と `APP_VERSION`（app.js）を一緒に上げる。** sw.js の FILES に新しいファイルを足すのも忘れない。
- `tests/cases.json` … ルールの具体例（手計算の期待値）。Web と将来の Swift で共通。
- `tests/core.test.js` … テスト本体。ブラウザなら `tests/index.html`、Node なら `node tests/run-node.mjs`。
- `tools/make_icons.py` … アイコン作成（Pillow）。
- `docs/rules.md`（出典）、`docs/decisions.md`（決定ログ）、`docs/mac-setup.md`（B の準備）。

## 動かし方（Windows）
- この PC には Node がない。`.claude/launch.json` の `pickle-score`（python http.server、ポート 8123）で開き、
  画面は `/web/index.html`、テストは `/tests/index.html`。
- push すると GitHub Actions が Node でテストし、通れば `web/` を GitHub Pages に公開する。

## 公開
- https://shinichi-sunayama.github.io/pickle-score/ （リポジトリ shinichi-sunayama/pickle-score、公開）
- `shinichi-sunayama.github.io` リポジトリ（app-ads.txt・工房サイト）には絶対にさわらない。

## 守ること
- 外部サービス・解析・広告なし。データは端末内の localStorage だけ。
- ルールを変えるときは、まず `tests/cases.json` に手計算の例を足してから `core.js` を直す。
- 決めたことは `docs/decisions.md` に追記する。
