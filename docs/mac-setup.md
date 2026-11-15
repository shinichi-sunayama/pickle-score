# B の準備：Mac で iPhone＋Apple Watch 版を作るための手順

A（ウェブ版）で数え方を実戦で確かめたあと、Mac でこの手順を進めます。上から順に1回ずつ行えば大丈夫です。

## 1. macOS を新しくする

- 「システム設定」→「一般」→「ソフトウェアアップデート」。最新の Xcode は新しめの macOS を必要とします。
- 空き容量は 40GB 以上あると安心です（Xcode とシミュレーターが大きいため）。

## 2. Xcode を入れる

1. Mac の App Store で「Xcode」を検索して入手（無料・数十分かかります）。
2. 一度起動して、追加の部品のインストールに同意します。
3. 最初の画面で、iOS と watchOS のシミュレーター（パソコン上で動く試し用の iPhone／Watch）を入れます。あとからでも「Xcode」→「Settings」→「Components」で入れられます。

## 3. Apple Developer アカウントでサインイン

1. Xcode →「Settings」→「Accounts」→ 左下の「＋」→「Apple ID」。
2. Apple Developer Program に登録しているアカウントでサインインします。
3. チーム名（屋号）が表示されれば OK。

## 4. ターミナルの準備（Git と GitHub）

「ターミナル」アプリを開いて、次を順に入力します。

```bash
xcode-select --install
```

（Git などの開発用の小さな道具が入ります。もう入っていれば「already installed」と出ます）

GitHub の操作には gh を使います。まず Homebrew（Mac 用の道具の入れ物）を https://brew.sh の手順で入れてから：

```bash
brew install gh
```

```bash
gh auth login
```

（画面の質問には GitHub.com → HTTPS → ブラウザでログイン、を選びます）

## 5. Claude Code を入れる

公式の手順（https://docs.claude.com/ja/docs/claude-code/setup ）に従います。デスクトップアプリ（Claude）の Code タブから使うのがいちばん簡単です。ターミナルで使う場合は、公式サイトに書かれているインストール用のコマンドを使ってください。

## 6. リポジトリを取り込む

```bash
mkdir -p ~/Claude && cd ~/Claude && gh repo clone shinichi-sunayama/pickle-score
```

Claude Code で `~/Claude/pickle-score` を開き、「CLAUDE.md と docs を読んで、B（iPhone＋Apple Watch 版）を始めて」と頼めば続きから進められます。

## 7. B で Claude に伝えること（メモ）

- 数え方は `web/core.js` を Swift に移す。テストは `tests/cases.json` をそのまま読み込んで同じ結果になることを確かめる。
- Watch 単体でも数えられること（試合中に iPhone をコートに持ち込まない人もいるため）。
- おはぎきなこ工房の名前で、チワちくシリーズとは別の作品として出す。
- 外部サービス・解析なし、個人情報を集めない（App Store のプライバシー表示は「データの収集なし」にできるように）。
- iOS のビルドは基本 Mac の Xcode で行い、GitHub Actions の macOS（無料枠が少ない）は使わない。
