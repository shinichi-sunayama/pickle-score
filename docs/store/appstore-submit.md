# App Store 審査に出す手順（おはぎのピックルボールコール 1.0）

ほかの作品（ほえほえチワ隊・いぬのはんこ屋さん・あみあみおさんぽ など）で分かった注意点を反映しています。

## 先に読む注意（ほかの作品で起きたこと）
- **ページごとに右上の「保存」を押す**。押さずに別のページへ行くと、入れた内容が消える。
- 説明文に「■」「★」「……」を使うと「無効な文字」ではじかれる。下の文はそれらを使っていない（【】と・だけ）。
- 初回は **Guideline 2.1「Information Needed（情報の追加依頼）」** が来ることが多い（RUN・だんご・あみあみで来た）。不合格ではなく質問。下の「2.1 が来たとき」で返す。返したあと **「App Review に再提出」を押さないと止まったまま**。
- ビルド番号は一度使うと使えない（クラウドの組み立てで自動で増える）。
- 「Upload Symbols Failed」は警告だけで、アップロードは成功している。
- リリースは **手動**（審査が通っても自動で公開しない）。

## 1. アプリ情報（左の「一般」→「App 情報」）
日本語だけでよい（英語のページは作らない）。アプリの画面が日本語だけなので、英語の説明を付けると英語で使えると誤解されるため。ほかの国のストアでも日本語の説明がそのまま出る。
| 項目 | 入れるもの |
|---|---|
| 名前 | おはぎのピックルボールコール |
| サブタイトル（30文字まで） | ダブルスの得点を数えて読み上げ |
| カテゴリ | プライマリ：スポーツ／セカンダリ：ユーティリティ |
| コンテンツ配信権 | 「はい、サードパーティのコンテンツを含み、使用する権利があります」（VOICEVOX の声・フォント） |
| 年齢制限指定 | 「編集」→ 質問はすべて「いいえ／なし」。最後の「子ども向け（Made for Kids）」は「該当なし」→ 4+ |

## 2. 価格と配信状況
- 価格：**無料**（広告・課金なし）
- 配信地域：ほかの作品と同じく、**中国本土・EU 27か国・アイスランド・ノルウェー・ロシア・ベラルーシを外す**。韓国はゲームではないので入れてよい。Mac・Vision Pro で使えるようにするチェックは外す。

## 3. App のプライバシー（左の「App のプライバシー」）
- プライバシーポリシー URL：https://shinichi-sunayama.github.io/pickle-score/privacy.html （いまの App Store Connect では「App 情報」ではなく、この「App のプライバシー」のページに欄がある）
- 「データを収集していますか？」→ **いいえ** →「保存」→ 右上の **「公開」**

## 4. バージョン 1.0 のページ（左の「iOS App」の「1.0」）
バージョンの数字は **1.0** のまま（「1.00」にしない）。ビルドの版も 1.0。

### プロモーション用テキスト（170文字まで）
```
ボタン2つでピックルボールの得点コールを数えて大きく表示。Apple Watch だけでも使えて、ずんだもんたちの声で読み上げもできます。
```

### 説明（4000文字まで）
```
ピックルボールのサーブ前に言う得点のコール（例：4-2-1）を、ボタンを押すだけで数えて表示します。試合中にカウントが分からなくなる初心者の方でも安心です。

【かんたん操作】
・ボタンは「サーブ側がラリーを取った」「落とした」の2つだけ
・いま言うコールを大きく表示（試合のはじめは 0-0-2）
・右と左のどちらからサーブするかを、コートの図で表示
・押しまちがえても「1つ戻す」でやり直せます

【Apple Watch 対応】
・Watch だけで数えられるので、iPhone をコートに持ち込まなくても使えます
・ボタンを押すと手首の振動でお知らせ

【読み上げ】
・コールを英語の数字で読み上げます（0-0-2 は「ゼロ・ゼロ・ツー」）
・端末の声のほか、ずんだもん・四国めたん・春日部つむぎの声も選べます
・iPhone はマナーモードでも読み上げます

【ルール】
・ダブルス／シングルス
・サーブ側だけ得点（ふつう）／毎ラリー得点
・11点・15点・21点、2点差／1点差
・USA Pickleball 公式ルールブック 2026年版にもとづいて数えます（このアプリは非公式で、USA Pickleball とは関係ありません）

【そのほか】
・試合の履歴を30件まで保存し、ラリーごとのコールをあとから確かめられます
・試合中は画面が消えません
・広告なし、アカウント登録なし。個人情報は集めず、データは端末の中だけに保存します

【クレジット】
VOICEVOX:ずんだもん
VOICEVOX:四国めたん
VOICEVOX:春日部つむぎ
フォント：M PLUS Rounded 1c（SIL Open Font License 1.1）

おはぎきなこ工房
```
クレジットは VOICEVOX の規約で「アプリの紹介画面など」に載せる決まり（docs/voices.md）。説明文から消さない。

### キーワード（100文字まで、カンマのあとに空白を入れない）
```
得点,スコア,カウント,スコアボード,ダブルス,シングルス,サーブ,審判,スポーツ,記録,パドル,ウォッチ,読み上げ,初心者
```
名前やサブタイトルにある言葉（ピックルボール・おはぎ・コール・得点を数え…）は入れなくてよい。ほかのアプリ名・商標（キャラクター名を含む）は入れない。

### サポート URL・マーケティング URL
- サポート URL：https://shinichi-sunayama.github.io/pickle-score/support.html（連絡先は工房のメール。ほかの作品のような Google フォームは必須ではない。作ったら URL を Claude に渡せばページのリンクを差し替える）
- マーケティング URL：https://shinichi-sunayama.github.io/pickle-score/ （ウェブ版）

### 著作権
```
2026 おはぎきなこ工房
```
（© は App Store が自動で付ける）

### スクリーンショット
`docs/store/screenshots/` の画像を使う（クラウドのシミュレーターで撮影。撮り直しは `gh workflow run screenshots.yml`）。
- **iPhone**：「6.3 インチ」の欄に `iphone/1_main.png` → `2_over.png` → `3_history.png` → `4_settings.png` の順（1206×2622）。ほかの大きさの欄は空でよい。
- **Apple Watch**：Watch の欄に `watch/1_main.png` → `2_over.png` → `3_menu.png`。
- PNG のアップロードが止まったら、軽い JPEG にしたものを使う（あみあみおさんぽで起きた）。

### ビルド
「ビルド」の「＋」で **1.0（3）** を選ぶ（2026-11-15 15:53 ごろに上げたもの。クラウドの run 43687076549）。
※ 最初の 3 回は Xcode が App Store Connect 側でビルド番号を 1・2・3 に振り直していた（版も標準の 1.0 のまま）。次からは `apple.yml` で振り直しを止め、Actions の実行番号がそのままビルド番号になる（3 より大きいので問題なし）。Watch アプリは同じビルドの中に入っている。

### App Review に関する情報
- サインインが必要：**いいえ**
- 連絡先：名前（ローマ字）・電話番号（+81 から）・メールは、ユーザーが自分で入れる
- メモ（英語。日本語のページで入れて保存する。ほえほえチワ隊で空に見えたことがあるので、保存後にもう一度確認）：
```
Ohagi Pickleball Call counts the score call that pickleball players say before each serve (for example "4-2-1" = serving team score, receiving team score, server number; a doubles game starts at "0-0-2").

No account or sign-in is needed. How to test:
1. Tap the green button (the serving side won the rally) or the red button (the serving side lost the rally). The large number shows the next call, and the court picture shows which side to serve from.
2. "1つ戻す" (Undo) goes back one rally. The clock button shows game history; the gear button opens settings (rules and voice).
3. The Apple Watch app works on its own with the same two buttons. The "..." menu has new game, rules, voice and recent games.

Scoring follows the USA Pickleball Official Rulebook 2026. This app is unofficial and not affiliated with USA Pickleball.
The voices were generated with VOICEVOX (commercial use allowed with credit; credits are in Settings and in the description). The dog pictures and icon are our own.
No data leaves the device: no ads, no analytics, no tracking.

Answers we were asked for on earlier first submissions (Guideline 2.1), given in advance:
1. Purpose and audience: helps pickleball players, especially beginners, keep track of the score call during recreational games.
2. External services: none (no server, ads, analytics, tracking or account).
3. Regional differences: none (Japanese interface, works the same everywhere).
4. Third-party material: VOICEVOX voices (commercial use allowed with credit), M PLUS Rounded 1c font (SIL Open Font License). The dog pictures and icon are our own.
A screen recording from a physical iPhone, starting on the Home Screen, is attached.
```

### 添付ファイル（審査用の画面収録、最初から付ける）
ほかの作品は初回に毎回 2.1 で動画を求められたので、最初から付けて往復を減らす（必須ではない）。
1. 実機の iPhone で「画面収録」を始め、**ホーム画面から**「おはぎコール」を開く。緑・赤のボタンを何回か、「1つ戻す」、履歴（時計のボタン）、設定で声を選ぶ（試しに鳴る）まで、30秒〜1分。
2. 動画を Claude に渡す → `tools/review-video.ps1`（ほえほえチワ隊のものを流用）と同じ方法で、ホーム画面のぼかし・無音・30fps・高さ 1920 に加工する。**加工前の動画はそのまま付けない**（壁紙・通知が映る）。
3. 「App Review に関する情報」の「添付ファイル」に加工した動画を付けて「保存」。
- 2026-11-15 加工済み：`C:\Users\sunay\Dropbox\iOSアプリ用\OhagiPickleballCall_v1.0_AppReview_iPhone.mp4`（50秒、888×1920、30fps、無音。最初の 1.7 秒はアイコン以外をぼかし。chiwa-survivor の `tools/review-video.ps1 -BlurSeconds 1.7 -Keep 0.15,0.55,0.23,0.125`）
- Apple Watch は画面収録ができないので、メモの説明だけでよい。

### バージョンのリリース
**「このバージョンを手動でリリースする」** を選ぶ。

## 5. 審査に出す
右上の「審査用に追加」→「審査へ提出」。入れ忘れがあると赤い文字で出るので、その項目を直して「保存」。

## 6. 2.1（Information Needed）が来たとき
1. 実機の iPhone で、**ホーム画面から**アプリを開いて使う様子を画面収録する（コントロールセンターの「画面収録」）。Watch の様子も入れられれば入れる。
   - 壁紙・ドック・通知が映るので、そのまま添付しない。Claude に渡せば、ぼかし・無音・30fps・高さ約1920 に加工する（ほかの作品の `tools/review-video.ps1` と同じ方法）。
2. 返信（英語）と、App Review のメモに同じ文を入れる。下はひな形（ほかの作品の `docs/store/appstore-review-reply.md` と同じ形）：
```
Thank you for reviewing our app.

1. Purpose and audience: Ohagi Pickleball Call helps pickleball players, especially beginners, keep track of the score call during recreational games. Anyone who plays pickleball can use it.
2. How to use: tap the green button when the serving side wins a rally and the red button when it loses one. The app shows the next score call (e.g. 4-2-1) and which side to serve from. Undo goes back one rally. The Apple Watch app works the same way on its own.
3. External services: none. The app does not use a server, ads, analytics or tracking, and has no account. All data stays on the device.
4. Regional differences: none. The app works the same in every region (Japanese interface).
5. Third-party material: the voices were generated with VOICEVOX, whose terms allow commercial use with credit (credits are shown in the app's Settings and in the description). The font is M PLUS Rounded 1c (SIL Open Font License). The dog pictures and the icon are our own.

A screen recording from a physical iPhone is attached.
```
3. 返信したら **「App Review に再提出」** を押す。
