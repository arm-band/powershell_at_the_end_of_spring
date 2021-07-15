# 春の湊に (At the end of spring)

## Abstract

`.git/config` に記述されているリモートリポジトリのポート番号を書き換えるバッチ。

## Usage

1. `start.bat` をダブルクリックで起動してください
2. 対話式CLIでポート番号を変更したい Git リモートリポジトリ の設定が存在する Gitリポジトリ のディレクトリパスを入力してください

## Settings

`config.json` で設定される項目の一覧です。

- `gitConfig`:
    - `repository`:
        - `originPort`(String): 変換対象のポート番号
        - `modifiedPort`(String): 変換したいポート番号