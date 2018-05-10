MISCモジュール
=============

たまに必要なる機能のHDLモジュール集です。


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
- cdb_signal_moduleは共通ポートに加えて下記の固有ポートを持ちます。

|port|型|入出力|説明|
|---|---|---|---|
|in_sig|std_logic|input|入力信号です。|
|out_sig|std_logic|output|クロックブリッジされたin_sigの信号が出力されます。伝達のレイテンシはin_clkとout_clkのクロック状態により決まります。|
|out_riseedge|std_logic|output|out_sigの立ち上がりエッジのタイミングでパルスを出力します。|
|out_falledge|std_logic|output|out_sigの立ち下がりエッジのタイミングでパルスを出力します。|

cdb_stream_module 固有ポート
---------------------------
- cdb_stream_moduleは共通ポートに加えて下記の固有ポートを持ちます。

|port|型|入出力|説明|
|---|---|---|---|
|in_valid|std_logic|input|入力信号です。in_readyが'0'の時にin_validをアサートした場合は、in_readyが'1'になるまで入力の状態を保持しなければなりません。|
|in_ready|std_logic|output|モジュールの状態を返します。in_readyが'0'の時にin_validをアサートした場合は、in_readyが'1'になるまで入力の状態を保持しなければなりません。|
|out_valid|std_logic|output|クロックブリッジされたin_validの信号が出力されます。out_validがアサートされた時、out_readyが'0'であれば'1'になるまで状態を保持します。|
|out_ready|std_logic|input|外部からの待機を指示します。out_readyが'0'の間はout_validのアサート状態を保持します。|

cdb_data_module 固有ポート
--------------------------
- cdb_data_moduleは共通ポートおよびcdb_stream_module固有ポートに加えて下記の固有ポートを持ちます。

|generic|型|パラメータ|説明|
|---|---|---|---|
|DATA_BITWIDTH|integer|1～1024|データポートのビット幅を指示します。|

|port|型|入出力|説明|
|---|---|---|---|
|in_data|std_logic_vector|input|in_validに'1'が指示された場合にin_readyが'1'であればデータが取り込まれます。|
|out_data|std_logic_vector|output|out_validが'1'の時に取り込まれたデータが有効になります。out_validがアサートされた時、out_readyが'0'であれば'1'になるまで状態を保持します。|


