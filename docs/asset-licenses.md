# 使っている素材と利用条件

| 素材 | 場所 | 出どころ | 権利者 | 条件 | クレジット | 確認日 |
|---|---|---|---|---|---|---|
| フォント M PLUS Rounded 1c Bold（使う文字だけに減らしたもの） | `web/fonts/mplus-rounded-bold.woff2` | Google Fonts（元ファイルは chiwa-survivor の `Assets/_Game/Resources/Fonts/MPLUSRounded1c-Bold.ttf`）、`tools/make_font.py` で作成 | The Rounded M+ Project Authors | SIL Open Font License 1.1（`web/fonts/OFL.txt`）。減らした版も OFL のまま | 設定画面に表示 | 2026-11-15 |
| 犬5匹の絵（おはぎ・きなこ・しらたま・どらやき・ようかん）と、おはぎの顔 | `web/img/dogs/*.png` | chiwa-survivor の `Assets/_Game/Resources/DogSprites/*.png` を `tools/import_dogs.py` で縮小・切り抜き | おはぎきなこ工房（元はユーザーが Meshy の有料プランで作った 3D モデルを描き出した絵） | Meshy 有料プランの条件（商用利用可・クレジット不要）。公開前に Meshy の最新の規約を確認する（chiwa-survivor の `docs/asset-licenses.md`） | 不要 | 2026-11-15 |
| 読み上げの声（ずんだもん・四国めたん・春日部つむぎ） | `web/voices/<id>/*.wav` | VOICEVOX 0.23.0 で作成（`tools/make_voices.py`） | 各キャラクターの権利者 | 商用可・クレジット必須・音声の二次配布は禁止（[voices.md](voices.md)） | 必要（設定画面に「VOICEVOX:〇〇」） | 2026-11-15 |
| アプリのアイコン | 元の絵 `docs/art/icon/app_icon_gemini.jpg` → `web/icons/`（`tools/make_icons.py`） | Google Gemini で生成（おねがいの文は [art/icon.md](art/icon.md)、見本はおはぎの絵）。ユーザーが選んだ1枚 | おはぎきなこ工房（Gemini で生成） | Google の生成 AI の利用規約に従う（出力の利用はユーザーの責任。App Store に出す前に最新の規約を確認する） | 不要 | 2026-11-15 |
