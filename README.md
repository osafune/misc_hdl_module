MISCモジュール集
===============

たまに必要なる機能のHDLモジュール集です。

|ファイル|エンティティ名|説明|
|---|---|---|
|div_module.vhd|[div_module](#div_module)|符号無し整数同士の除算モジュール|
|delay_module.vhd|[delay_module](#delay_module)|任意幅・任意長のデータ遅延モジュール|
|cdb_module.vhd|[cdb_signal_module](#cdb_signal_module-固有ポート)|レベル信号の単方向クロックドメインブリッジ|
||[cdb_stream_module](#cdb_stream_module-固有ポート)|トリガ信号のハンドシェーク・クロックドメインブリッジ|
||[cdb_data_module](#cdb_data_module-固有ポート)|任意幅のデータのハンドシェーク・クロックドメインブリッジ|
|vga_syncgen.vhd|[vga_syncgen](#vga_syncgen)|ビデオ信号およびカラーバー信号生成モジュール|
|dvi_encoder.vhd|[dvi_encoder](#dvi_encoder)|ビデオ信号をDVI/HDMI信号にエンコードする|
|uart_module.v|[uart_phy_txd](#uart_phy_txd)|AvalonST バイトストリームをUARTで送信する|
||[uart_phy_rxd](#uart_phy_rxd)|UARTを受信してAvalonST バイトストリームとして出力する|
||[uart_to_bytes](#uart_to_bytes)|Platform Designer用のコンポーネント|
|spdif_tx_24bit.vhd|[spdif_tx_24bit](#spdif_tx_24bit)|24bit/192kHz対応のS/PDIFエンコーダーモジュール|
|adat_encoder.vhd|[adat_encoder](#adat_encoder)|24bit/48kHz×8ch出力対応のADATエンコーダーモジュール|

ライセンス
=========
[The MIT License (MIT)](https://opensource.org/licenses/MIT)  
Copyright (c) 2022 J-7SYSTEM WORKS LIMITED.


使い方
=====

各HDLソースをプロジェクトに追加してモジュールをインスタンスしてください。


-------------------------------------------------------------------------------
div_module
----------

- 符号無し整数同士の割り算を行います。インスタンス時に除数と被除数のビット幅およびマルチサイクル／パイプラインを選択できます。

|generic|型|パラメータ|説明|
|---|---|---|---|
|DIVIDER_TYPE|string|"MULTICYCLE"<br>"PIPELINED"|割り算器の構成を選択します。|
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
- cdb_data_moduleは[共通ポート](#共通ポート)および[cdb_stream_module固有ポート](#cdb_stream_module-固有ポート)に加えて下記の固有ポートを持ちます。

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
- 任意のビデオ信号およびARIBライクなカラーバー信号を生成するモジュールです。  
色と割合はARIB STD-B28(HDTVマルチフォーマットカラーバー)の割合に準拠し、ビデオ信号期間に合わせて自動的にスケーリングされます。また下1/4部分の黒レベルテスト部分はRGB画像では意味が無いため、R/G/B各色のランプ信号に差し替えています。

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
|csync|std_logic|output|複合同期期間に'1'を出力します。|
|hblank|std_logic|output|水平ブランク期間に'1'を出力します。|
|vblank|std_logic|output|垂直ブランク期間に'1'を出力します。|
|dotenable|std_logic|output|ドットイネーブル期間に'1'を出力します。|
|cb_rout|std_logic_vector|output|カラーバーのR信号を8bitで出力します。|
|cb_gout|std_logic_vector|output|カラーバーのG信号を8bitで出力します。|
|cb_bout|std_logic_vector|output|カラーバーのB信号を8bitで出力します。|


-------------------------------------------------------------------------------
dvi_encoder
-----------
- ビデオ信号（RGB 4:4:4/8bit）をDVI/HDMI信号にエンコードするモジュールです。信号はDVIフォーマットのみでHDMIで追加された機能（オーディオパケットなど）は対応していません。
- このモジュールは信号のエンコードのみを行います。DVI/HDMI信号への電気的な変換は外部回路で行う必要があります。

|generic|型|パラメータ|説明|
|---|---|---|---|
|DEVICE_FAMILY|string|"Cyclone III"<br>"Cyclone IV E"<br>"Cyclone V"<br>"MAX 10"|実装するデバイスファミリを指定します。|

|port|型|入出力|説明|
|---|---|---|---|
|reset|std_logic|input|非同期リセット入力です。'1'の期間中、リセットをアサートします。|
|clk|std_logic|input|ドットクロックを入力です。全ての信号は立ち上がりエッジで動作します。|
|clk_x5|std_logic|input|シリアライズクロック入力です。clkポートのクロックと同相(0 deg)の5倍の周波数のクロックを入力します。|
|vga_r|std_logic_vector|input|8bitのビデオR信号入力です。|
|vga_g|std_logic_vector|input|8bitのビデオG信号入力です。|
|vga_b|std_logic_vector|input|8bitのビデオB信号入力です。|
|vga_de|std_logic|input|ドットイネーブル信号入力です。'1'の場合にvga_r,vga_g,vga_bのデータが取り込まれます。|
|vga_hsync|std_logic|input|水平同期信号入力です。'1'の場合に同期期間となります。|
|vga_vsync|std_logic|input|垂直同期信号入力です。'1'の場合に同期期間となります。||
|data0_p|std_logic|output|DVI/HDMIのDATA0p信号出力です。|
|data0_n|std_logic|output|DVI/HDMIのDATA0n信号出力です。|
|data1_p|std_logic|output|DVI/HDMIのDATA1p信号出力です。|
|data1_n|std_logic|output|DVI/HDMIのDATA1n信号出力です。|
|data2_p|std_logic|output|DVI/HDMIのDATA2p信号出力です。|
|data2_n|std_logic|output|DVI/HDMIのDATA2n信号出力です。|
|clock_p|std_logic|output|DVI/HDMIのCLOCKp信号出力です。|
|clock_n|std_logic|output|DVI/HDMIのCLOCKn信号出力です。|

**※ピン設定について**
- _p/_nのピンは差動信号で動作するため、隣接あるいはLVDSペアのピンに配置してください。
- VREFピン等の高速信号に対応していないピンへ配置しないよう注意してください。
- 必要に応じてピンI/O規格の設定および外部回路にて電気特性を調整してください。


-------------------------------------------------------------------------------
uart_phy_txd
------------

- AvalonSTバイトストリームからUARTのデータを送信します。

|generic|型|パラメータ|説明|
|---|---|---|---|
|CLOCK_FREQUENCY|integer|50000000(デフォルト)|clkポートに入力するクロック周波数を指定します。|
|UART_BAUDRATE|integer|115200(デフォルト)|送信するUARTのボーレートを指定します。|
|UART_STOPBIT|integer|1(デフォルト) or 2|UARTのストップビット長を指定します。|

|port|型|入出力|説明|
|---|---|---|---|
|reset|std_logic|input|非同期リセット入力です。'1'の期間中、リセットをアサートします。|
|clk|std_logic|input|クロック入力です。全ての信号は立ち上がりエッジで動作します。|
|clk_ena|std_logic|input|クロックイネーブル入力です。'1'の時にクロックが有効になります。|
|in_ready|std_logic|output|モジュールの状態を返します。in_readyが'0'の時にin_validをアサートした場合は、in_readyが'1'になるまで入力の状態を保持しなければなりません。|
|in_valid|std_logic|input|バイトデータ入力信号です。in_readyが'0'の時にin_validをアサートした場合は、in_readyが'1'になるまで入力の状態を保持しなければなりません。|
|in_data|std_logic_vector|input|in_validに'1'が指示された場合にin_readyが'1'であれば8bitのバイトデータが取り込まれ、UART送信されます。|
|txd|std_logic|output|UARTの信号出力です。|
|cts|std_logic|input|フロー制御の通信可入力です。'1'のときにUART送信を実行します。フロー制御を使用しない場合は'1'に固定します。|


-------------------------------------------------------------------------------
uart_phy_rxd
------------

- UARTのデータを受信してAvalonSTバイトストリームへ変換します。

|generic|型|パラメータ|説明|
|---|---|---|---|
|CLOCK_FREQUENCY|integer|50000000(デフォルト)|clkポートに入力するクロック周波数を指定します。|
|UART_BAUDRATE|integer|115200(デフォルト)|受信するUARTのボーレートを指定します。|
|UART_STOPBIT|integer|1(デフォルト)<br>2|UARTのストップビット長を指定します。|

|port|型|入出力|説明|
|---|---|---|---|
|reset|std_logic|input|非同期リセット入力です。'1'の期間中、リセットをアサートします。|
|clk|std_logic|input|クロック入力です。全ての信号は立ち上がりエッジで動作します。|
|clk_ena|std_logic|input|クロックイネーブル入力です。'1'の時にクロックが有効になります。|
|out_ready|std_logic|input|AvalonSTシンク側からの待機を指示します。out_readyが'0'の間はout_validのアサート状態を保持します。|
|out_valid|std_logic|output|受信したバイトデータの有効信号が出力されます。out_validがアサートされた時、out_readyが'0'であれば'1'になるまで状態を保持します。|
|out_data|std_logic_vector|output|受信した8bitのバイトデータが出力されます。out_validがアサートされた時、out_readyが'0'であれば'1'になるまで状態を保持します。|
|out_error|std_logic_vector|output|受信エラーのステータスを指示します。<br>bit 0:オーバーフローエラー発生のとき'1'を指示します。out_dataのリードが行われると'0'にクリアされます。<br>bit 1:フレーミングエラー発生のとき'1'を指示します。次のデータが正常に受信されると'0'にクリアされます。|
|rxd|std_logic|input|UARTの信号入力です。|
|rts|std_logic|output|フロー制御の送信リクエスト信号です。受信可能なとき'1'を指示します。|


-------------------------------------------------------------------------------
uart_to_bytes
-------------

- AvalonSTバイトストリームとUARTの変換を行います。uart_phy_rxdおよびuart_phy_txdのインスタンスを行ったモジュールです。  
このモジュールは同梱のuart_to_bytes_hw.tclと同フォルダに格納してPlatform Designer上からインスタンスします。  
Platform Designer上から変更できるパラメータは以下の通りです。

|generic|型|パラメータ|説明|
|UART_BAUDRATE|integer|115200(デフォルト)|送信するUARTのボーレートを指定します。|
|UART_STOPBIT|integer|1(デフォルト) or 2|UARTのストップビット長を指定します。|


-------------------------------------------------------------------------------
spdif_tx_24bit
------------

- 24bitステレオオーディオデータをS/PDIF信号にエンコードします。

|generic|型|パラメータ|説明|
|---|---|---|---|
|COPYRIGHTS|string|"ENABLE"(デフォルト)<br>"NONE"|コピーライト信号の有効、無効を設定します。|
|CLOCK_ACCURACY|string|"STANDARD"(デフォルト)<br>"VARIABLE"<br>"HIQUALITY"|送信するクロックの精度情報を設定します。|
|COPY_CONTROL|string|"NONE"(デフォルト)<br>"ONCE"<br>"LIMIT"|コピーコントロール情報を設定します。|
|CATEGORY_CODE|std_logic_vector|"00000000"(デフォルト)|機器カテゴリーコードを設定します。|

|port|型|入出力|説明|
|---|---|---|---|
|reset|std_logic|input|非同期リセット入力です。'1'の期間中、リセットをアサートします。|
|clk|std_logic|input|クロックを入力です。サンプリングレートの128倍(128fs)以上の周波数を入力します。全ての信号は立ち上がりエッジで動作します。|
|clk_ena|std_logic|input|クロックイネーブル信号入力です。'1'の時にクロックが有効になります。クロックが送信ビットレートよりも高速な場合、この信号で分周します。|
|first_frame|std_logic|output|先頭サブフレーム送信の間'1'が出力されます。周期はfsと等しくなります。|
|end_frame|std_logic|output|最終サブフレーム送信の間'1'が出力されます。周期はfsと等しくなります。|
|freq_code|std_logic_vector|input|送信するフレームのサンプリング周波数情報をセットします。<br>0000 : 44.1kHz<br>0010 : 48kHz<br>0011 : 32kHz<br>1000 : 88.2kHz<br>1010 : 96kHz<br>1100 : 176.4kHz<br>1110 : 192kHz|
|dlen_code|std_logic_vector|input|送信するフレームのサンプリングビット数情報をセットします。<br>0000 : 追加情報なし<br>0010 : 16bit<br>1010 : 20bit<br>1011 : 24bit|
|pcmdata_l,<br>pcmdata_r|std_logic_vector|input|左/右チャネルのサンプリングデータを入力します。24bitソース以外では左詰（MSB詰め）で設定します。データラッチは各サブフレームの先頭で取り込まれるため、fs期間でデータを維持しなければなりません。|
|spdif_out|std_logic|output|S/PDIFデータ出力です。|


-------------------------------------------------------------------------------
adat_encoder
------------

- 24bit、8chオーディオデータをADAT信号にエンコードします。

|port|型|入出力|説明|
|---|---|---|---|
|reset|std_logic|input|非同期リセット入力です。'1'の期間中、リセットをアサートします。|
|clk|std_logic|input|クロックを入力です。サンプリングレートの256倍(256fs)以上の周波数を入力します。全ての信号は立ち上がりエッジで動作します。|
|clk_ena|std_logic|input|クロックイネーブル信号入力です。'1'の時にクロックが有効になります。クロックが送信ビットレートよりも高速な場合、この信号で分周します。|
|ch0_data,<br>ch1_data,<br>ch2_data,<br>ch3_data,<br>ch4_data,<br>ch5_data,<br>ch6_data,<br>ch7_data|std_logic_vector|input|各チャネルのサンプリングデータを入力します。24bitソース以外では左詰（MSB詰め）で設定します。|
|usercode|std_logic_vector|input|ユーザー追加情報（MIDI信号など）を入力します。|
|sync_out|std_logic|output|chN_dataおよびusercodeを取り込むfs同期信号を出力します。データは'1'→'0'の変化と同時に取り込まれるため、fs期間中に保持しておく必要はありません。|
|adat_tx|std_logic|output|ADATデータ出力です。|
