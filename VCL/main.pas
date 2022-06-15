unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, wclBluetooth, StdCtrls, ComCtrls;

type
  TfmMain = class(TForm)
    wclBluetoothManager: TwclBluetoothManager;
    btDiscover: TButton;
    btRefresh: TButton;
    btConnect: TButton;
    btDisconnect: TButton;
    wclRfCommClient: TwclRfCommClient;
    lvDevices: TListView;
    lbLog: TListBox;
    btClear: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btClearClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btDiscoverClick(Sender: TObject);
    procedure wclBluetoothManagerDiscoveringStarted(Sender: TObject;
      const Radio: TwclBluetoothRadio);
    procedure wclBluetoothManagerDeviceFound(Sender: TObject;
      const Radio: TwclBluetoothRadio; const Address: Int64);
    procedure wclBluetoothManagerDiscoveringCompleted(Sender: TObject;
      const Radio: TwclBluetoothRadio; const Error: Integer);
    procedure btRefreshClick(Sender: TObject);
    procedure btConnectClick(Sender: TObject);
    procedure wclBluetoothManagerAfterOpen(Sender: TObject);
    procedure wclBluetoothManagerBeforeClose(Sender: TObject);
    procedure wclBluetoothManagerConfirm(Sender: TObject;
      const Radio: TwclBluetoothRadio; const Address: Int64;
      out Confirm: Boolean);
    procedure wclBluetoothManagerNumericComparison(Sender: TObject;
      const Radio: TwclBluetoothRadio; const Address: Int64;
      const Number: Cardinal; out Confirm: Boolean);
    procedure wclBluetoothManagerAuthenticationCompleted(Sender: TObject;
      const Radio: TwclBluetoothRadio; const Address: Int64;
      const Error: Integer);
    procedure wclRfCommClientConnect(Sender: TObject;
      const Error: Integer);
    procedure wclRfCommClientDisconnect(Sender: TObject;
      const Reason: Integer);
    procedure wclRfCommClientData(Sender: TObject; const Data: Pointer;
      const Size: Cardinal);
    procedure btDisconnectClick(Sender: TObject);

  private
    FAddress: Int64;

    procedure RefreshDevice(const Item: TListItem;
      const Radio: TwclBluetoothRadio); overload;
    procedure RefreshDevice(const Address: Int64;
      const Radio: TwclBluetoothRadio); overload;

    procedure Trace(const Msg: string); overload;
    procedure Trace(const Msg: string; const Res: Integer); overload;
  end;

var
  fmMain: TfmMain;

implementation

uses
  wclUUIDs, wclErrors, wclBluetoothErrors;

{$R *.dfm}

procedure TfmMain.FormCreate(Sender: TObject);
var
  Res: Integer;
begin
  wclRfCommClient.Service := HandsfreeServiceClass_UUID;

  Res := wclBluetoothManager.Open;
  if Res <> WCL_E_SUCCESS then
    Trace('Bluetooth manager open error', Res);
end;

procedure TfmMain.RefreshDevice(const Item: TListItem;
  const Radio: TwclBluetoothRadio);
var
  Address: Int64;
  Res: Integer;
  ClassicRadio: TwclBluetoothRadio;
  Name: string;
  Paired: Boolean;
  Connected: Boolean;
begin
  if Item <> nil then begin
    Address := StrToInt64('$' + Item.Caption);

    // Use first found radio if not provided.
    if Radio = nil then
      Res := wclBluetoothManager.GetClassicRadio(ClassicRadio)
    else begin
      ClassicRadio := Radio;
      Res := WCL_E_SUCCESS;
    end;

    if Res = WCL_E_SUCCESS then begin
      Res := ClassicRadio.GetRemoteName(Address, Name);
      if Res = WCL_E_SUCCESS then
        Item.SubItems[0] := Name
      else
        Item.SubItems[0] := 'Error: 0x' + IntToHex(Res, 8);

      Res := ClassicRadio.GetRemotePaired(Address, Paired);
      if Res = WCL_E_SUCCESS then
        Item.SubItems[1] := BoolToStr(Paired, True)
      else
        Item.SubItems[1] := 'Error: 0x' + IntToHex(Res, 8);

      Res := ClassicRadio.GetRemoteConnectedStatus(Address, Connected);
      if Res = WCL_E_SUCCESS then
        Item.SubItems[2] := BoolToStr(Connected, True)
      else
        Item.SubItems[2] := 'Error: 0x' + IntToHex(Res, 8);
    end;
  end;
end;

procedure TfmMain.btClearClick(Sender: TObject);
begin
  lbLog.Items.Clear;
end;

procedure TfmMain.Trace(const Msg: string);
begin
  lbLog.Items.Add(Msg);
end;

procedure TfmMain.Trace(const Msg: string; const Res: Integer);
begin
  Trace(Msg + ': 0x' + IntToHex(Res, 8));
end;

procedure TfmMain.FormDestroy(Sender: TObject);
begin
  wclBluetoothManager.Close;
end;

procedure TfmMain.btDiscoverClick(Sender: TObject);
var
  Res: Integer;
  Radio: TwclBluetoothRadio;
begin
  Res := wclBluetoothManager.GetClassicRadio(Radio);
  if Res <> WCL_E_SUCCESS then
    Trace('Get classic radio failed', Res)

  else begin
    Res := Radio.Discover(10, dkClassic);
    if Res <> WCL_E_SUCCESS then
      Trace('Start discovering failed', Res)
  end;
end;

procedure TfmMain.wclBluetoothManagerDiscoveringStarted(Sender: TObject;
  const Radio: TwclBluetoothRadio);
begin
  lvDevices.Items.Clear;

  Trace('Discovering started');
end;

procedure TfmMain.wclBluetoothManagerDeviceFound(Sender: TObject;
  const Radio: TwclBluetoothRadio; const Address: Int64);
var
  Item: TListItem;
begin
  Item := lvDevices.Items.Add;
  Item.Caption := IntToHex(Address, 12);
  Item.SubItems.Add('');
  Item.SubItems.Add('');
  Item.SubItems.Add('');
end;

procedure TfmMain.wclBluetoothManagerDiscoveringCompleted(Sender: TObject;
  const Radio: TwclBluetoothRadio; const Error: Integer);
var
  i: Integer;
begin
  if Error = WCL_E_SUCCESS then
    Trace('Discovering completed success')
  else
    Trace('Discovering completed with error', Error);

  if lvDevices.Items.Count > 0 then begin
    for i := 0 to lvDevices.Items.Count - 1 do
      RefreshDevice(lvDevices.Items[i], Radio);
  end;
end;

procedure TfmMain.btRefreshClick(Sender: TObject);
begin
  RefreshDevice(lvDevices.Selected, nil);
end;

procedure TfmMain.btConnectClick(Sender: TObject);
var
  Address: Int64;
  Res: Integer;
  Radio: TwclBluetoothRadio;
  Services: TwclBluetoothServices;
  Connected: Boolean;
  Paired: Boolean;
begin
  if lvDevices.Selected = nil then
    Trace('Select device')

  else begin
    Res := wclBluetoothManager.GetClassicRadio(Radio);
    if Res <> WCL_E_SUCCESS then
      Trace('Get classic radio failed', Res)

    else begin
      Address := StrToInt64('$' + lvDevices.Selected.Caption);

      // Try to enumerate device's service. We are looking for HFP.
      Res := Radio.EnumRemoteServices(Address, @HandsfreeServiceClass_UUID,
        Services);
      if Res <> WCL_E_SUCCESS then
        Trace('Enumerate remote device services failed', Res)

      else begin
        if Length(Services) = 0 then
          Trace('Hands Free Profile not found')

        else begin
          // Check device connection status.
          Res := Radio.GetRemoteConnectedStatus(Address, Connected);
          if Res <> WCL_E_SUCCESS then
            Trace('Get connected status failed', Res)

          else begin
            // If connected - disconnect
            if Connected then begin
              Res := Radio.RemoteDisconnect(Address);
              if Res <> WCL_E_SUCCESS then
                Trace('Disconnect failed', Res);
            end;

            if Res = WCL_E_SUCCESS then begin
              // Check pairing status.
              Res := Radio.GetRemotePaired(Address, Paired);
              if Res <> WCL_E_SUCCESS then
                Trace('Get paired status failed', Res)

              else begin
                if Paired then begin
                  Res := Radio.RemoteUnpair(Address);
                  if Res <> WCL_E_SUCCESS then
                    Trace('Unpair failed', Res);
                end;

                if Res = WCL_E_SUCCESS then begin
                  // Now start pairing
                  FAddress := Address;
                  Res := Radio.RemotePair(Address, pmClassic);
                  if Res <> WCL_E_SUCCESS then begin
                    Trace('Start pairing failed', Res);
                    FAddress := 0;
                  end;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure TfmMain.wclBluetoothManagerAfterOpen(Sender: TObject);
begin
  Trace('Bluetooth manager opened');
  FAddress := 0;
end;

procedure TfmMain.wclBluetoothManagerBeforeClose(Sender: TObject);
begin
  Trace('Bluetooth manager closing');
end;

procedure TfmMain.wclBluetoothManagerConfirm(Sender: TObject;
  const Radio: TwclBluetoothRadio; const Address: Int64;
  out Confirm: Boolean);
begin
  // Process only selected device
  if Address = FAddress then begin
    Trace('Pairing with device. Just Waorks pairing.');
    // Accept always.
    Confirm := True;
  end else
    Confirm := False;
end;

procedure TfmMain.wclBluetoothManagerNumericComparison(Sender: TObject;
  const Radio: TwclBluetoothRadio; const Address: Int64;
  const Number: Cardinal; out Confirm: Boolean);
begin
  // Process only selected device
  if Address = FAddress then begin
    Trace('Pairing with device. Numeric comparison.');
    // Accept always.
    Confirm := True;
  end else
    Confirm := False;
end;

procedure TfmMain.wclBluetoothManagerAuthenticationCompleted(
  Sender: TObject; const Radio: TwclBluetoothRadio; const Address: Int64;
  const Error: Integer);
var
  Res: Integer;
begin
  // Process only selected device
  if Address = FAddress then begin
    FAddress := 0;

    RefreshDevice(Address, Radio);

    if Error <> WCL_E_SUCCESS then
      Trace('Authentication failed', Error)

    else begin
      // Device paired. Install HFP service.
      Res := Radio.InstallDevice(Address, HandsfreeServiceClass_UUID);
      if Res <> WCL_E_SUCCESS then
        Trace('Install device failed', Res)
      else begin
        // Start RFCOMM connection.
        wclRfCommClient.Address := Address;
        Res := wclRfCommClient.Connect(Radio);
        if Res <> WCL_E_SUCCESS then
          Trace('Start connection failed', Res);
      end;
    end;
  end;
end;

procedure TfmMain.RefreshDevice(const Address: Int64;
  const Radio: TwclBluetoothRadio);
var
  i: Integer;
  AddrStr: string;
  Item: TListItem;
begin
  if lvDevices.Items.Count > 0 then begin
    AddrStr := IntToHex(Address, 12);
    Item := nil;
    for i := 0 to lvDevices.Items.Count - 1 do begin
      if AddrStr = lvDevices.Items[i].Caption then begin
        Item := lvDevices.Items[i];
        Break;
      end;
    end;
    if Item <> nil then
      RefreshDevice(Item, Radio);
  end;
end;

procedure TfmMain.wclRfCommClientConnect(Sender: TObject;
  const Error: Integer);
begin
  if Error <> WCL_E_SUCCESS then
    Trace('Connect failed', Error)
  else
    Trace('Connected');

  RefreshDevice(wclRfCommClient.Address, wclRfCommClient.Radio);
end;

procedure TfmMain.wclRfCommClientDisconnect(Sender: TObject;
  const Reason: Integer);
begin
  Trace('Device disconnected. Reason', Reason);

  // Remove service.
  wclRfCommClient.Radio.UninstallDevice(wclRfCommClient.Address,
    HandsfreeServiceClass_UUID);
  // Unpair device.
  wclRfCommClient.Radio.RemoteUnpair(wclRfCommClient.Address);

  RefreshDevice(wclRfCommClient.Address, wclRfCommClient.Radio);
end;

procedure TfmMain.wclRfCommClientData(Sender: TObject; const Data: Pointer;
  const Size: Cardinal);
var
  Str: string;
begin
  if (Data <> nil) and (Size > 0) then begin
    Trace('Data received');
    SetLength(Str, Size);
    CopyMemory(Pointer(Str), Data, Size);
    Trace('  ' + Str);
  end;
end;

procedure TfmMain.btDisconnectClick(Sender: TObject);
var
  Res: Integer;
begin
  Res := wclRfCommClient.Disconnect;
  if Res <> WCL_E_SUCCESS then
    Trace('Disconnect failed', Res);
end;

end.
