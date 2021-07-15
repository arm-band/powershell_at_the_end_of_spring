# Shift-JIS でコード記述

######################
# 環境設定            #
######################

# ファイル出力時の文字コード設定
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

######################
# グローバル変数      #
######################
[String]$configPath = Join-Path ( Convert-Path . ) 'config.json'

######################
# 関数               #
######################

##
# Find-ErrorMessage: エラーメッセージ組み立て
#
# @param {Int} $code: エラーコード
# @param {String} $someStr: 一部エラーメッセージで使用する文字列
#
# @return {String} $msg: 出力メッセージ
#
function Find-ErrorMessage([Int]$code, [String]$someStr) {
    $msg = ''
    $errMsgObj = [Hashtable]@{
        # 1x: 設定ファイル系
        11 = '設定ファイル (config.json) が存在しません。'
        # 2x: Git 設定ファイル系
        21 = '指定された ディレクトリ が存在しません。'
        22 = 'Git設定ファイル (.git/config) が存在しません。'
        ## 31～39: リモートリポジトリ
        31 = 'リモートリポジトリ のオリジナルの ポート番号 が指定されていません。'
        32 = 'リモートリポジトリ のオリジナルの ポート番号 が見付かりませんでした。'
        33 = 'リモートリポジトリ の変換後の ポート番号 の値が不正です。'
        34 = 'リモートリポジトリ の変換後の ポート番号 が指定されていません。'
        35 = 'リモートリポジトリ の変換後の ポート番号 の値が不正です。'
        # 9x: その他、処理中エラー
        99 = '##########'
    }
    $msg = $errMsgObj[$code]
    if ($someStr.Length -gt 0) {
        $msg = $msg.Replace('##########', $someStr)
    }

    return $msg
}
##
# Show-ErrorMessage: エラーメッセージ出力
#
# @param {Int} $code: エラーコード
# @param {Boolean} $exitFlag: exit するかどうかのフラグ
# @param {String} $someStr: 一部エラーメッセージで使用する文字列
#
function Show-ErrorMessage([Int]$code, [Boolean]$exitFlag, [String]$someStr) {
    $msg = Find-ErrorMessage $code $someStr
    Write-Host('ERROR ' + $code + ': ' + $msg) -BackgroundColor DarkRed
    Write-Host `r`n

    if ($exitFlag) {
        exit
    }
}

##
# Assert-ParamStrGTZero: パラメータ文字列長さチェック
#
# @param {String} $paramStr: ファイルパス
#
# @return {Boolean} : 文字長が0より大きければ True, そうでなければ False
#
function Assert-ParamStrGTZero([String]$paramStr) {
    return ($paramStr.Length -gt 0)
}
##
# Assert-ExistFile: ファイル存在チェック
#
# @param {String} $filePath: ファイルパス
#
# @return {Boolean} : ファイルが存在すれば True, そうれなければ False
#
function Assert-ExistFile([String]$filePath) {
    return (Test-Path $filePath)
}
##
# Assert-NumberFormat: 文字列形式チェック
#
# @param {String} $asciiStr: 文字列
#
# @return {Boolean} : 文字列が半角数字だけで構成されていれば True, そうれなければ False
#
function Assert-NumberFormat([String]$asciiStr) {
    return ($asciiStr -match "^[0-9]+$")
}

##
# Assert-URLFormat: URL形式チェック
#
# @param {String} $str: URLを含む文字列
#
# @return {Boolean} : URLがポート番号付きで正しいと思しき形式ならば True, そうれなければ False
#
function Assert-URLFormat([String]$str) {
    return ($str -match "url[\s]?=[\s]?https?://([^:/]+):([0-9]+)(/?.*)")
}

##
# Set-GitConfig: Git のグローバル設定を実施。内部で Invoke-ExternalCommand により Git を外部プロセスとして起動
#
# @param {String} $configPath: config.json.sample のファイルパス
# @param {String} $configPath: config.json のファイルパス
#
function Set-GitConfig([String]$configPath) {
    Write-Host '設定ファイル (config.json) を読み込みます ...'
    Write-Host `r`n
    if (-not (Assert-ExistFile $configPath)) {
        Show-ErrorMessage 11 $True ''
    }

    # 設定ファイル 読み込み
    $configData = Get-Content -Path $configPath -Raw -Encoding UTF8 | ConvertFrom-JSON
    # 初期設定
    Write-Host 'Git リモートリポジトリ の ポート番号を変更します。'
    Write-Host `r`n

    # リモートリポジトリ
    if (-not (Assert-ParamStrGTZero $configData.gitConfig.repository.originPort) ) {
        Show-ErrorMessage 31 $True ''
    }
    if (-not (Assert-NumberFormat $configData.gitConfig.repository.originPort) ) {
        Show-ErrorMessage 33 $True ''
    }
    if (-not (Assert-ParamStrGTZero $configData.gitConfig.repository.modifiedPort) ) {
        Show-ErrorMessage 34 $True ''
    }
    if (-not (Assert-NumberFormat $configData.gitConfig.repository.modifiedPort) ) {
        Show-ErrorMessage 35 $True ''
    }

    # ローカルリポジトリ
    [String]$localRepositoryDir = Read-Host 'リモートリポジトリのポート番号を変更したい config が存在する Gitリポジトリ の ディレクトリパス を入力してください。'
    if (-not (Assert-ExistFile $localRepositoryDir)) {
        Show-ErrorMessage 21 $True ''
    }
    [String]$localRepositoryConfig = $localRepositoryDir + '\.git\config'
    if (-not (Assert-ExistFile $localRepositoryConfig)) {
        Show-ErrorMessage 22 $True ''
    }
    $content = Get-Content $localRepositoryConfig -Raw
    if (-not (Assert-URLFormat $content)) {
        Show-ErrorMessage 32 $True ''
    }
    else {
        Write-Host '============ Original settings - BEGIN ============'
        Write-Host $content
        Write-Host '============ Original settings - END ============'
        Write-Host `r`n
        $modifiedPort = $configData.gitConfig.repository.modifiedPort
        $modifiedContent = $content -replace "url(\s)?=(\s)?http(s)?://([^:/]+):([0-9]+)(/?.*)", "url`$1=`$2http`$3://`$4:$modifiedPort`$6"
        Write-Output $modifiedContent | Out-File $localRepositoryConfig

        Write-Host '============ Modified settings - BEGIN ============'
        Write-Host $modifiedContent
        Write-Host '============ Modified settings - END ============'
        Write-Host `r`n

        Write-Host 'Git リモートリポジトリ の ポート番号変更が完了しました。'
        Write-Host `r`n
    }
}

######################
# main process       #
######################
Set-GitConfig $configPath
