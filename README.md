# チーム内ルール（開発用）

## アーキテクチャ
- 基本構成：Model / View / ViewModel / Logic
- UI とロジックは分離する


### ファイル構成

```
Pikumei/
├── Model/            # アプリ内で扱うデータ構造（struct / enum）
│   └── ...

├── View/             # SwiftUI の画面
│   ├── Screens/      # 各画面（Scan / Result / Battle など）
│   └── Components/   # 再利用する UI コンポーネント

├── ViewModel/        # 状態管理・処理の呼び出し
│   ├── Logic/        # ゲームロジック（ステータス計算・バトル処理）
│   ├── ML/           # CoreML / Vision による分類処理
│   └── Camera/       # カメラ制御・画像取得

├── Utils/            # Extension 類
│   └── Extensions/
│       └── ...

├── Library/          # 非コードリソース
│   ├── Assets/       # 画像・色など
│   ├── MLModels/     # .mlmodel ファイル
│   └── Preview/      # SwiftUI Preview 用

```

## ブランチルール
- main：発表・デモ用
- develop：開発用
- feature/〇〇：機能開発

## コンフリクト時の対応
- コンフリクト状態を一度コミットする
- その後、修正した内容を別コミットとして追加する

## コミットルール
- コミットメッセージは日本語
- 変更の粒度を意識する（1コミット1変更）

----

# プロダクト名 
<!-- プロダクト名に変更してください -->

![プロダクト名](https://kc3.me/cms/wp-content/uploads/2026/02/444e7120d5cdd74aa75f7a94bf8821a5-scaled.png)
<!-- プロダクト名・イメージ画像を差し変えてください -->


## チーム名
チーム○ XXXX
<!-- チームIDとチーム名を入力してください -->


## 背景・課題・解決されること

<!-- テーマ「関西をいい感じに」に対して、考案するプロダクトがどういった(Why)背景から思いついたのか、どのよう(What)な課題があり、どのよう(How)に解決するのかを入力してください -->


## プロダクト説明

<!-- 開発したプロダクトの説明を入力してください -->


## 操作説明・デモ動画
[デモ動画はこちら](https://www.youtube.com/watch?v=fbzGp0XJGq8)
<!-- 開発したプロダクトの操作説明について入力してください。また、操作説明デモ動画があれば、埋め込みやリンクを記載してください -->


## 注力したポイント

<!-- 開発したプロダクトの中で、特に注力して作成した箇所・ポイントについて入力してください -->
### アイデア面

### デザイン面

### その他

## 使用技術

<!-- 使用技術を入力してください -->


<!--
markdownの記法はこちらを参照してください！
https://docs.github.com/ja/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax
-->
