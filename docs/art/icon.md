# アプリアイコン（Gemini で描く）

## 手順
1. Gemini（画像を作れるモデル）を開き、見本の絵を添付してから、下の「おねがいの文」を貼る。
   - 見本の絵：`web/img/dogs/ohagi.png`（おはぎ）
2. 何枚か作ってもらい、気に入った1枚を **`docs/art/icon/app_icon_gemini.png`**（jpg でも可）という名前で保存する。
   - 正方形でなくても大丈夫（真ん中を正方形に切り取ります）。1024×1024 以上が理想。
3. Claude に「アイコンを差し替えて」と頼む。`python tools/make_icons.py` がこの絵からホーム画面用のアイコン（180・192・512）を作る。
   - B（App Store 版）でも同じ絵を 1024×1024 にして使う。
4. 使った絵のことを `docs/asset-licenses.md` に書く（作った道具・日付・自分で選んだこと）。

## 気をつけること
- アイコンの主役はピックルボール（ボールとパドル）。何のアプリかがひと目で分かるように。おはぎは「顔をのぞかせる」くらいの脇役。
- 文字は入れない（小さいと読めない）。数字も入れない。
- 角は丸めない（iPhone が自動で丸める）。ふちに大事なものを置かない（ホーム画面で切れることがある）。
- 他の作品のキャラ・ロゴ・画風の名前（「〇〇風」）を文に入れない。
- アプリの色に合わせる：空色〜クリーム色、オレンジ、コートの緑。

## おねがいの文（日本語）
```
スマホアプリのアイコンを1枚描いてください。ピックルボール（パドルで穴あきボールを打つスポーツ）の得点を数えるアプリです。
・正方形、文字や数字はなし、角は丸めない、背景まで塗りつぶす（透明なし）
・主役は真ん中の大きな黄色いピックルボール（丸い穴がいくつもあいたプラスチックのボール）と、ななめに置いた木のパドル1本。ひと目でピックルボールとわかること
・添付の犬（白・黒・茶の3色で毛の長いチワワ）が、パドルのうしろ（右下）から顔と前足だけをちょこんとのぞかせて、うれしそうにボールを見上げている。犬は脇役で、ボールより小さく
・背景はやわらかい空色からクリーム色へのグラデーション、下のほうに明るい緑のコートと白いラインを少しだけ。小さなきらきら
・やわらかい塗り、太めのふち線、明るくはっきりした色、やさしい雰囲気。小さく表示してもボールとパドルだとすぐわかる形
・ふちの近くには大事なものを置かない
```

## Prompt (English)
```
Please draw one app icon for a smartphone app that keeps score in pickleball (a paddle sport played with a plastic ball full of holes).
- Square, no text or numbers, no rounded corners, fully painted background (no transparency)
- The main subject in the center: a large yellow pickleball (a plastic ball with many round holes) and one wooden paddle placed diagonally. It must read as pickleball at a glance
- The attached dog (a long-haired white, black and tan chihuahua) peeks out from behind the paddle at the lower right, showing only its face and front paws, happily looking up at the ball. The dog is a supporting character, smaller than the ball
- Background: a soft gradient from sky blue to cream, with a little bright green court and white lines near the bottom, small sparkles
- Soft shading, thick outlines, bright clear colors, a gentle mood; still recognizable as a ball and paddle when tiny
- Keep important things away from the edges
```
