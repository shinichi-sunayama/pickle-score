# iPhone＋Apple Watch 版を TestFlight で試す（Mac なし）

Mac がなくても、GitHub のクラウドの Mac で組み立て・署名し、TestFlight に上げられます。
このリポジトリは公開なので、クラウドの Mac は無料で使えます（チワちくの月 200 分の枠は減りません）。

## 段階
| 段階 | 内容 | だれが | 状態 |
|---|---|---|---|
| 1 | Swift のアプリを書く（`apple/`） | Claude | 済（2026-11-15、署名なしの組み立て成功：Xcode 26.6、run 43681472505） |
| 2 | バンドル ID を 2 つ登録し、App Store Connect にアプリを作る | ユーザー | 済（2026-11-15） |
| 3 | このリポジトリの GitHub の Secrets に鍵を 4 つ入れる | ユーザー | |
| 4 | クラウドで組み立て・署名して App Store Connect に上げる | Claude | |
| 5 | TestFlight で iPhone に入れ、Watch にも入れて試す | ユーザー | |

## 2. バンドル ID を登録して、アプリを作る（ユーザー）

### 2-1. バンドル ID（アプリの名札）を 2 つ登録
1. https://developer.apple.com/account/resources/identifiers/list を開く
2. 「＋」→「App IDs」→「Continue」→「App」→「Continue」
3. 説明（Description）`PickleCall`、Bundle ID は「Explicit」で **`com.ohagikinakokobo.picklecall`** →「Continue」→「Register」
4. もう一度 2. から。説明 `PickleCall Watch`、Bundle ID **`com.ohagikinakokobo.picklecall.watchkitapp`**
   - 機能（Capabilities）のチェックはどちらも何も付けなくてよい

### 2-2. App Store Connect にアプリを作る
1. https://appstoreconnect.apple.com/ →「アプリ」→ 左上の「＋」→「新規 App」
2. 次のように入れて「作成」
   - プラットフォーム：iOS
   - 名前：`おはぎのピックルボールコール`（ホーム画面の名前は「おはぎコール」）
   - 主言語：日本語
   - バンドル ID：`com.ohagikinakokobo.picklecall`
   - SKU：`picklecall`
   - ユーザーアクセス：アクセス制限なし
3. ストアの文章や画像はまだ入れなくてよい（TestFlight で試すだけなら不要）
   - Watch アプリは iPhone アプリの中に入って一緒に届くので、Watch 用に別のアプリを作る必要はない

## 3. GitHub に鍵を 4 つ入れる（ユーザー）
ほえほえチワ隊・くっつきチワだんご・チワちくRUN と**同じ値**です（チームの API キーなので、同じチームのどのアプリにも使える）。
1. https://github.com/shinichi-sunayama/pickle-score/settings/secrets/actions を開く
2. 「New repository secret」を押し、Name と Secret を入れて「Add secret」。これを 4 回
   | Name | Secret に入れるもの |
   |---|---|
   | `ASC_KEY_ID` | App Store Connect の API キーの「キー ID」 |
   | `ASC_ISSUER_ID` | 同じ画面の上にある「Issuer ID」 |
   | `ASC_KEY_P8` | キーのファイル `AuthKey_<キーID>.p8` をメモ帳で開いた中身ぜんぶ（`-----BEGIN PRIVATE KEY-----` から `-----END PRIVATE KEY-----` まで） |
   | `APPLE_TEAM_ID` | Apple Developer のチーム ID（10 文字） |
   - キー ID と Issuer ID は https://appstoreconnect.apple.com/access/integrations/api で見られる
   - .p8 はほかの作品のときに保存したもの。見つからなければ同じ画面で新しいキーを作り、ほかの作品の Secrets もいっしょに入れかえる
   - 鍵は Claude に送らない。GitHub の画面にだけ入れる
   - 公開リポジトリでも Secrets の中身はほかの人には見えない（ほかの人からの変更依頼（プルリクエスト）の実行でも渡らない）

## 4. クラウドで作って上げる（Claude）
Actions の「Apple build」（`.github/workflows/apple.yml`）を手で起動します。
```
gh workflow run apple.yml -R shinichi-sunayama/pickle-score -f upload=true
```
- 鍵がないときは、署名なしで組み立てられるかだけを確かめる
- ビルド番号は Actions の実行番号を使うので、上げるたびに自動で増える
- 結果：https://github.com/shinichi-sunayama/pickle-score/actions/workflows/apple.yml

## 5. TestFlight で試す（ユーザー）
1. 上がってから数分〜数十分で、App Store Connect の「おはぎのピックルボールコール」→「TestFlight」にビルドが出る（「処理中」が消えるまで待つ）
2. 左の「内部テスト」の「＋」でグループを作り（名前は何でもよい）、自分をテスターに入れて、ビルドを追加
3. iPhone の「TestFlight」アプリ（ほかの作品で使っているもの）→「おはぎのピックルボールコール」→「インストール」
4. Apple Watch には、iPhone の「Watch」アプリ →「マイウォッチ」→ 下のほうの「おはぎコール」→「インストール」（自動で入ることもある）

## 気をつけること
- バンドル ID は一度使うと変えられない
- Watch アプリは Watch だけで数えられる（iPhone を持ってコートに入らなくてよい）。iPhone と Watch の数えはまだ別々（同期はあとで検討）
