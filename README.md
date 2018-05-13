MISCモジュール集
===============

たまに必要なる機能のHDLモジュール集です。

|ファイル|エンティティ名|説明|
|---|---|---|
|div_module.vhd|[div_module](#div_module)|符号無し整数同士の除算モジュール|
|delay_module.vhd|[delay_module](#delay_module)|任意幅・任意長のデータ遅延モジュール|
|cdb_module.vhd|[cdb_signal_module](#cdb_signal_module)|レベル信号の単方向クロックドメインブリッジ|
||[cdb_stream_module](#cdb_stream_module)|トリガ信号のハンドシェーク・クロックドメインブリッジ|
||[cdb_data_module](#cdb_data_module)|任意幅のデータのハンドシェーク・クロックドメインブリッジ|
|vga_syncgen.vhd|[vga_syncgen](#vga_syncgen)|ビデオ信号およびカラーバー信号生成モジュール|


ライセンス
=========
[The MIT License (MIT)](https://opensource.org/licenses/MIT)  
Copyright (c) 2018 J-7SYSTEM WORKS LIMITED.


使い方
=====

各HDLソースをプロジェクトに追加してモジュールをインスタンスしてください。

-------------------------------------------------------------------------------
div_module
----------

- 符号無し整数どうしの割り算を行います。インスタンス時に除数と被除数のビット幅およびマルチサイクル／パイプラインを選択できます。

|generic|型|パラメータ|説明|
|---|---|---|---|
|DIVIDER_TYPE|string|"MULTICYCLE" or "PIPELINED"|割り算器の構成を選択します。|
|DIVIDEND_BITWIDTH|integer|2～256|被除数のビット幅を指定します。|
|DIVISOR_BITWIDTH|integer|2～DIVIDEND_BITWIDTH|除数のビット幅をDIVIDEND_BITWIDTH以下の範囲で指定します。|

|port|型|入出力|説明|
|---|---|---|---|
|reset|std_logc|input|モジュール全体の非同期リセットです。'1'の期間中リセットをアサートします。|
|clk|std_logic|input|モジュールのクロック入力です。全てのレジスタは立ち上がりエッジで駆動されます。|
|dividend|std_logic_vector|input|被除数データを入力します。データ有効状態でモジュールに取り込まれます。|
|divisor|std_logic_vector|input|除数データを入力します。データ有効状態でモジュールに取り込まれます。|
|in_valid|std_logic|input|dividend,divisorの値が有効であることを指示します。in_validに'1'を指示した時in_readyが'1'であればデータ有効となり、モジュールに取り込まれます。in_readyが'0'の時にin_validをアサートした場合は、in_readyが'1'になるまで入力の状態を保持しなければなりません。|
|in_ready|std_logic|output|モジュールの状態を返します。in_validに'1'が入力された時、in_readyが'1'であればデータ有効状態となります。in_readyが'0'の時にin_validをアサートした場合は、in_readyが'1'になるまで入力の状態を保持しなければなりません。|
|quotient|std_logic_vector|output|out_validが'1'の時、割り算の商が出力されます。商は被除数と同じビット幅になります。|
|remainder|std_logic_vector|output|out_validが'1'の時、割り算の余りが出力されます。余りは除数と同じビット幅になります。|
|out_valid|std_logic|output|quotient,remainderに有効な値が出力されていることを示します。out_readyが'0'の場合は状態を保持します。|
|out_ready|std_logic|input|データ出力を待機させたい場合には'0'を入力します。|


-------------------------------------------------------------------------------
delay_module
------------
- データ遅延用のディレイパイプラインを構成します。ディレイ量により自動的にメモリマクロへフィッティングされます。

|generic|型|パラメータ|説明|
|---|---|---|---|
|DATA_BITWIDTH|integer|1～1024|データポートのビット幅を指定します。|
|DELAY_CLOCKNUMBER|integer|1～65535|遅延させるクロック数を指定します。|

|port|型|入出力|説明|
|---|---|---|---|
|clk|std_logic|input|モジュールのクロック入力です。全てのレジスタは立ち上がりエッジで駆動されます。|
|enable|std_logic|input|クロックイネーブル入力です。enableが'1'の時にデータシフトが行われます。|
|data_in|std_logic_vector|input|データ入力です。|
|data_out|std_logic_vector|output|指定したクロック分、遅延したデータが出力されます。|


-------------------------------------------------------------------------------
cdb_module
----------
- クロックドメインブリッジモジュールです。以下の3つのエンティティが含まれています。  
  - cdb_signal_module  
    レベル信号を伝達するモジュールです。
  - cdb_stream_module  
    ハンドシェークで信号を伝達するモジュールです。信号はAvalonSTのsource/sinkのサブセットです。
  - cdb_data_module  
    ハンドシェークでビット幅あるデータを伝達するモジュールです。信号はAvalonSTのsource/sinkのサブセットです。

  全てのモジュールで、自動的にSDCへのset_false_path設定が行われます。

共通ポート
---------

|port|型|入出力|説明|
|---|---|---|---|
|in_rst|std_logic|input|入力側の非同期リセット入力です。'1'の期間中リセットをアサートします。|
|in_clk|std_logic|input|入力側のクロック入力です。全てのレジスタは立ち上がりエッジで駆動されます。|
|out_rst|std_logic|input|出力側の非同期リセット入力です。'1'の期間中リセットをアサートします。|
|out_clk|std_logic|input|出力側のクロック入力です。全てのレジスタは立ち上がりエッジで駆動されます。|

cdb_signal_module 固有ポート
---------------------------
- cdb_signal_moduleは[共通ポート](#共通ポート)に加えて下記の固有ポートを持ちます。

|port|型|入出力|説明|
|---|---|---|---|
|in_sig|std_logic|input|入力信号です。|
|out_sig|std_logic|output|クロックブリッジされたin_sigの信号が出力されます。伝達のレイテンシはin_clkとout_clkのクロック状態により決まります。|
|out_riseedge|std_logic|output|out_sigの立ち上がりエッジのタイミングでパルスを出力します。|
|out_falledge|std_logic|output|out_sigの立ち下がりエッジのタイミングでパルスを出力します。|

cdb_stream_module 固有ポート
---------------------------
- cdb_stream_moduleは[共通ポート](#共通ポート)に加えて下記の固有ポートを持ちます。

|port|型|入出力|説明|
|---|---|---|---|
|in_valid|std_logic|input|入力信号です。in_readyが'0'の時にin_validをアサートした場合は、in_readyが'1'になるまで入力の状態を保持しなければなりません。|
|in_ready|std_logic|output|モジュールの状態を返します。in_readyが'0'の時にin_validをアサートした場合は、in_readyが'1'になるまで入力の状態を保持しなければなりません。|
|out_valid|std_logic|output|クロックブリッジされたin_validの信号が出力されます。out_validがアサートされた時、out_readyが'0'であれば'1'になるまで状態を保持します。|
|out_ready|std_logic|input|外部からの待機を指示します。out_readyが'0'の間はout_validのアサート状態を保持します。|

cdb_data_module 固有ポート
--------------------------
- cdb_data_moduleは[共通ポート](#共通ポート)および[cdb_stream_module固有ポート](#cdb_stream_module)に加えて下記の固有ポートを持ちます。

|generic|型|パラメータ|説明|
|---|---|---|---|
|DATA_BITWIDTH|integer|1～1024|データポートのビット幅を指示します。|

|port|型|入出力|説明|
|---|---|---|---|
|in_data|std_logic_vector|input|in_validに'1'が指示された場合にin_readyが'1'であればデータが取り込まれます。|
|out_data|std_logic_vector|output|out_validが'1'の時に取り込まれたデータが有効になります。out_validがアサートされた時、out_readyが'0'であれば'1'になるまで状態を保持します。|


-------------------------------------------------------------------------------
vga_syncgen
-----------
- 任意のビデオ信号およびカラーバー信号を生成するモジュールです。カラーバーはビデオ信号期間に合わせて自動的にスケーリングされます。

|generic|型|パラメータ|説明|
|---|---|---|---|
|H_TOTAL|integer|16～65535|水平方向のドット数を指定します。|
|H_SYNC|integer|8～H_TOTAL|水平同期信号のドット幅を指定します。|
|H_BACKP|integer|0～H_TOTAL|水平バックポーチ（水平同期終了から表示開始までの期間）のドット数を指定します。|
|H_ACTIVE|integer|8～H_TOTAL|水平表示期間のドット数を指定します。有効なカラーバーを出力するためには32ドット以上必要です。|
|V_TOTAL|integer|8～65535|垂直方向のライン数を指定します。|
|V_SYNC|integer|1～V_TOTAL|垂直同期信号のライン数を指定します。|
|V_BACKP|integer|0～V_TOTAL|垂直バックポーチ（垂直同期終了から表示開始までの期間）のライン数を指定します。|
|V_ACTIVE|integer|8～V_TOTAL|垂直表示期間のライン数を指定します。有効なカラーバーを出力するためには16ライン以上必要です。|

※パラメータは下記の条件を満たさなければなりません。  
  - H_TOTAL ＞ H_SYNC + H_BACKP + H_ACTIVE
  - V_TOTAL ＞ V_SYNC + V_BACKP + V_ACTIVE

|port|型|入出力|説明|
|---|---|---|---|
|reset|std_logic|input|非同期リセット入力です。'1'の期間中、リセットをアサートします。|
|video_clk|std_logic|input|ビデオクロック（ドットクロック）入力です。全ての信号は立ち上がりエッジで動作します。|
|scan_ena|std_logic|input|フレームバッファ走査イネーブル入力です。フレーム開始時にサンプルされ、'1'がセットされている場合はフレームバッファ制御用の信号を出力します。|
|framestart|std_logic|output|フレームの先頭でHSYNC期間の間'1'を出力します。|
|linestart|std_logic|output|scan_enaがアサートされていた場合、映像出力が有効なラインの先頭でHSYNC期間の間'1'を出力します。|
|pixelena|std_logic|output|scan_enaがアサートされていた場合、表示領域のドットの時に'1'を出力します。|
|hsync|std_logic|output|水平同期期間に'1'を出力します。|
|vsync|std_logic|output|垂直同期期間に'1'を出力します。|
|hblank|std_logic|output|水平ブランク期間に'1'を出力します。|
|vblank|std_logic|output|垂直ブランク期間に'1'を出力します。|
|dotenable|std_logic|output|ドットイネーブル期間に'1'を出力します。|
|cb_rout|std_logic_vector|output|カラーバーのR信号を8bitで出力します。|
|cb_gout|std_logic_vector|output|カラーバーのG信号を8bitで出力します。|
|cb_bout|std_logic_vector|output|カラーバーのB信号を8bitで出力します。|

