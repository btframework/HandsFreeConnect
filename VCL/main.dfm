object fmMain: TfmMain
  Left = 475
  Top = 336
  BorderStyle = bsSingle
  Caption = 'HandsFree Connect Demo Application'
  ClientHeight = 350
  ClientWidth = 517
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object btDiscover: TButton
    Left = 8
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Discover'
    TabOrder = 0
    OnClick = btDiscoverClick
  end
  object btRefresh: TButton
    Left = 104
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Refresh'
    TabOrder = 1
    OnClick = btRefreshClick
  end
  object btConnect: TButton
    Left = 200
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Connect'
    TabOrder = 2
    OnClick = btConnectClick
  end
  object btDisconnect: TButton
    Left = 288
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Disconnect'
    TabOrder = 3
    OnClick = btDisconnectClick
  end
  object lvDevices: TListView
    Left = 8
    Top = 40
    Width = 497
    Height = 105
    Columns = <
      item
        Caption = 'Address'
        Width = 150
      end
      item
        Caption = 'Name'
        Width = 150
      end
      item
        Caption = 'Paired'
        Width = 80
      end
      item
        Caption = 'Connected'
        Width = 80
      end>
    GridLines = True
    HideSelection = False
    ReadOnly = True
    RowSelect = True
    TabOrder = 4
    ViewStyle = vsReport
  end
  object lbLog: TListBox
    Left = 8
    Top = 152
    Width = 497
    Height = 161
    ItemHeight = 13
    TabOrder = 5
  end
  object btClear: TButton
    Left = 432
    Top = 320
    Width = 75
    Height = 25
    Caption = 'Clear'
    TabOrder = 6
    OnClick = btClearClick
  end
  object wclBluetoothManager: TwclBluetoothManager
    AfterOpen = wclBluetoothManagerAfterOpen
    BeforeClose = wclBluetoothManagerBeforeClose
    OnAuthenticationCompleted = wclBluetoothManagerAuthenticationCompleted
    OnConfirm = wclBluetoothManagerConfirm
    OnDeviceFound = wclBluetoothManagerDeviceFound
    OnDiscoveringCompleted = wclBluetoothManagerDiscoveringCompleted
    OnDiscoveringStarted = wclBluetoothManagerDiscoveringStarted
    OnNumericComparison = wclBluetoothManagerNumericComparison
    Left = 176
    Top = 80
  end
  object wclRfCommClient: TwclRfCommClient
    OnConnect = wclRfCommClientConnect
    OnData = wclRfCommClientData
    OnDisconnect = wclRfCommClientDisconnect
    Left = 264
    Top = 88
  end
end
