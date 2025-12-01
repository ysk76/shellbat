@echo off
setlocal ENABLEDELAYEDEXPANSION

REM ============================================================
REM  ▼ 設定
REM ============================================================

REM 読み込みファイル（ジョブグループ一覧）
set "ReadData=C:\JP1\data\group_list.txt"

REM ログ出力ディレクトリ（存在しなければ作成する）
set "LogDir=C:\JP1\log"

REM ============================================================
REM  ▼ 現在の年月を取得（YYYY/MM/DD フォーマット前提）
REM ============================================================

set YYYY=%date:~0,4%
set MM=%date:~5,2%

REM ============================================================
REM  ▼ 翌月計算（PowerShell 不使用）
REM ============================================================

if "%MM%"=="12" (
    set /a YYYY=%YYYY%+1
    set MM=01
) else (
    set /a MM=%MM%+1
    if !MM! LSS 10 (
        set MM=0!MM!
    )
)

REM ▼ YYYYMM
set next_month=%YYYY%%MM%

REM ▼ YYYY/MM
set next_month_slash=%YYYY%/%MM%

REM ============================================================
REM  ▼ 結果ファイルパス作成
REM ============================================================

set "ResultData=%LogDir%\result_%next_month%.txt"

if not exist "%LogDir%" (
    mkdir "%LogDir%"
)

REM ============================================================
REM  ▼ ログ開始
REM ============================================================

echo === JP1/AJS 翌月カレンダー取得開始 (%date% %time:~0,8%) === > "%ResultData%"
echo 対象月：%next_month_slash% >> "%ResultData%"
echo. >> "%ResultData%"

REM ============================================================
REM  ▼ 入力ファイル存在チェック
REM ============================================================

if not exist "%ReadData%" (
    echo [ERROR] 入力ファイル "%ReadData%" が存在しません。 >> "%ResultData%"
    goto END
)

REM ============================================================
REM  ▼ 1行ずつ ajsprint 実行
REM ============================================================

for /f "usebackq delims=" %%A in ("%ReadData%") do (
    set line=%%A

    if "!!line!!"=="" (
        REM 空行はスキップ
    ) else (
        REM ▼ ajsprint 実行（PowerShell 不使用）
        for /f "usebackq delims=" %%O in (`ajsprint -F AJSROOT1 -c "!!line!!" 2^>^&1`) do (
            set output=%%O
        )

        set ret=!errorlevel!

        if !ret!==0 (
            echo [OK]  !line! : !output! >> "%ResultData%"
        ) else (
            echo [ERROR] ajsprint failed (group: !line!, return: !ret!) >> "%ResultData%"
            echo          詳細: !output! >> "%ResultData%"
        )
    )
)

REM ============================================================
REM  ▼ 終了ログ
REM ============================================================

:END
echo. >> "%ResultData%"
echo === 完了 (%date% %time:~0,8%) === >> "%ResultData%"

REM ============================================================
REM  ▼ 必ず正常終了（JP1にアベンドさせない）
REM ============================================================

exit /b 0
