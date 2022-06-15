using System;
using System.Text;
using System.Windows.Forms;

using wclCommon;
using wclBluetooth;

namespace HandsFreeConnect
{
    public partial class fmMain : Form
    {
        private wclBluetoothManager FManager;
        private wclRfCommClient FClient;
        private Int64 FAddress;

        public fmMain()
        {
            InitializeComponent();
        }

        private void RefreshDevice(ListViewItem Item, wclBluetoothRadio Radio)
        {
            if (Item != null)
            {
                Int64 Address = Convert.ToInt64(Item.Text, 16);

                Int32 Res;
                wclBluetoothRadio ClassicRadio;
                // Use first found radio if not provided.
                if (Radio == null)
                    Res = FManager.GetClassicRadio(out ClassicRadio);
                else
                {
                    ClassicRadio = Radio;
                    Res = wclErrors.WCL_E_SUCCESS;
                }

                if (Res == wclErrors.WCL_E_SUCCESS)
                {
                    String Name;
                    Res = ClassicRadio.GetRemoteName(Address, out Name);
                    if (Res == wclErrors.WCL_E_SUCCESS)
                        Item.SubItems[1].Text = Name;
                    else
                        Item.SubItems[1].Text = "Error: 0x" + Res.ToString("X8");

                    Boolean Paired;
                    Res = ClassicRadio.GetRemotePaired(Address, out Paired);
                    if (Res == wclErrors.WCL_E_SUCCESS)
                        Item.SubItems[2].Text = Paired.ToString();
                    else
                        Item.SubItems[2].Text = "Error: 0x" + Res.ToString("X8");

                    Boolean Connected;
                    Res = ClassicRadio.GetRemoteConnectedStatus(Address, out Connected);
                    if (Res == wclErrors.WCL_E_SUCCESS)
                        Item.SubItems[3].Text = Connected.ToString();
                    else
                        Item.SubItems[3].Text = "Error: 0x" + Res.ToString("X8");
                }
            }
        }

        private void RefreshDevice(Int64 Address, wclBluetoothRadio Radio)
        {
            if (lvDevices.Items.Count > 0)
            {
                String AddrStr = Address.ToString("X12");
                ListViewItem Item = null;
                foreach (ListViewItem i in lvDevices.Items)
                {
                    if (AddrStr == i.Text)
                    {
                        Item = i;
                        break;
                    }
                }
                if (Item != null)
                    RefreshDevice(Item, Radio);
            }
        }

        private void Trace(String Msg)
        {
            lbLog.Items.Add(Msg);
        }

        private void Trace(String Msg, Int32 Res)
        {
            Trace(Msg + ": 0x" + Res.ToString("X8"));
        }

        private void fmMain_Load(Object sender, System.EventArgs e)
        {
            FManager = new wclBluetoothManager();
            FManager.OnDiscoveringStarted += FManager_OnDiscoveringStarted;
            FManager.OnDeviceFound += FManager_OnDeviceFound;
            FManager.OnDiscoveringCompleted += FManager_OnDiscoveringCompleted;
            FManager.AfterOpen += FManager_AfterOpen;
            FManager.BeforeClose += FManager_BeforeClose;
            FManager.OnConfirm += FManager_OnConfirm;
            FManager.OnNumericComparison += FManager_OnNumericComparison;
            FManager.OnAuthenticationCompleted += FManager_OnAuthenticationCompleted;

            FClient = new wclRfCommClient();
            FClient.Service = wclUUIDs.HandsfreeServiceClass_UUID;
            FClient.OnConnect += FClient_OnConnect;
            FClient.OnDisconnect += FClient_OnDisconnect;
            FClient.OnData += FClient_OnData;

            Int32 Res = FManager.Open();
            if (Res != wclErrors.WCL_E_SUCCESS)
                Trace("Bluetooth manager open error", Res);
        }

        private void FClient_OnData(Object Sender, Byte[] Data)
        {
            if (Data != null && Data.Length > 0)
            {
                Trace("Data received");
                String Str = Encoding.ASCII.GetString(Data);
                Trace("  " + Str);
            }
        }

        private void FClient_OnDisconnect(Object Sender, Int32 Reason)
        {
            Trace("Device disconnected. Reason", Reason);

            // Remove service.
            FClient.Radio.UninstallDevice(FClient.Address, wclUUIDs.HandsfreeServiceClass_UUID);
            // Unpair device.
            FClient.Radio.RemoteUnpair(FClient.Address);

            RefreshDevice(FClient.Address, FClient.Radio);
        }

        private void FClient_OnConnect(Object Sender, Int32 Error)
        {
            if (Error != wclErrors.WCL_E_SUCCESS)
                Trace("Connect failed", Error);
            else
                Trace("Connected");

            RefreshDevice(FClient.Address, FClient.Radio);
        }

        private void FManager_OnAuthenticationCompleted(Object Sender, wclBluetoothRadio Radio,
            Int64 Address, Int32 Error)
        {
            // Process only selected device
            if (Address == FAddress)
            {
                FAddress = 0;

                RefreshDevice(Address, Radio);

                if (Error != wclErrors.WCL_E_SUCCESS)
                    Trace("Authentication failed", Error);
                else
                {
                    // Device paired. Install HFP service.
                    Int32 Res = Radio.InstallDevice(Address, wclUUIDs.HandsfreeServiceClass_UUID);
                    if (Res != wclErrors.WCL_E_SUCCESS)
                        Trace("Install device failed", Res);
                    else
                    {
                        // Start RFCOMM connection.
                        FClient.Address = Address;
                        Res = FClient.Connect(Radio);
                        if (Res != wclErrors.WCL_E_SUCCESS)
                            Trace("Start connection failed", Res);
                    }
                }
            }
        }

        private void FManager_OnNumericComparison(Object Sender, wclBluetoothRadio Radio, Int64 Address,
            UInt32 Number, out Boolean Confirm)
        {
            // Process only selected device
            if (Address == FAddress)
            {
                Trace("Pairing with device. Numeric comparison.");
                // Accept always.
                Confirm = true;
            }
            else
                Confirm = false;
        }

        private void FManager_OnConfirm(Object Sender, wclBluetoothRadio Radio, Int64 Address,
            out Boolean Confirm)
        {
            // Process only selected device
            if (Address == FAddress)
            {
                Trace("Pairing with device. Just Waorks pairing.");
                // Accept always.
                Confirm = true;
            }
            else
                Confirm = false;
        }

        private void FManager_BeforeClose(Object sender, EventArgs e)
        {
            Trace("Bluetooth manager closing");
        }

        private void FManager_AfterOpen(Object sender, EventArgs e)
        {
            Trace("Bluetooth manager opened");
            FAddress = 0;
        }

        private void FManager_OnDiscoveringCompleted(Object Sender, wclBluetoothRadio Radio, Int32 Error)
        {
            if (Error == wclErrors.WCL_E_SUCCESS)
                Trace("Discovering completed success");
            else
                Trace("Discovering completed with error", Error);

            if (lvDevices.Items.Count > 0)
            {
                foreach (ListViewItem Item in lvDevices.Items)
                    RefreshDevice(Item, Radio);
            }
        }

        private void FManager_OnDeviceFound(Object Sender, wclBluetoothRadio Radio, Int64 Address)
        {
            ListViewItem Item = lvDevices.Items.Add(Address.ToString("X12"));
            Item.SubItems.Add("");
            Item.SubItems.Add("");
            Item.SubItems.Add("");
        }

        private void FManager_OnDiscoveringStarted(Object Sender, wclBluetoothRadio Radio)
        {
            lvDevices.Items.Clear();

            Trace("Discovering started");
        }

        private void btClear_Click(Object sender, EventArgs e)
        {
            lbLog.Items.Clear();
        }

        private void fmMain_FormClosed(Object sender, FormClosedEventArgs e)
        {
            FManager.Close();
        }

        private void btDiscover_Click(Object sender, EventArgs e)
        {
            wclBluetoothRadio Radio;
            Int32 Res = FManager.GetClassicRadio(out Radio);
            if (Res != wclErrors.WCL_E_SUCCESS)
                Trace("Get classic radio failed", Res);
            else
            {
                Res = Radio.Discover(10, wclBluetoothDiscoverKind.dkClassic);
                if (Res != wclErrors.WCL_E_SUCCESS)
                    Trace("Start discovering failed", Res);
            }
        }

        private void btRefresh_Click(Object sender, EventArgs e)
        {
            if (lvDevices.SelectedItems.Count > 0)
                RefreshDevice(lvDevices.SelectedItems[0], null);
        }

        private void btConnect_Click(Object sender, EventArgs e)
        {
            if (lvDevices.SelectedItems.Count == 0)
                Trace("Select device");
            else
            {
                wclBluetoothRadio Radio;
                Int32 Res = FManager.GetClassicRadio(out Radio);
                if (Res != wclErrors.WCL_E_SUCCESS)
                    Trace("Get classic radio failed", Res);
                else
                {
                    Int64 Address = Convert.ToInt64(lvDevices.SelectedItems[0].Text, 16);

                    // Try to enumerate device's service. We are looking for HFP.
                    wclBluetoothService[] Services;
                    Res = Radio.EnumRemoteServices(Address, wclUUIDs.HandsfreeServiceClass_UUID, out Services);
                    if (Res != wclErrors.WCL_E_SUCCESS)
                        Trace("Enumerate remote device services failed", Res);
                    else
                    {
                        if (Services == null || Services.Length == 0)
                            Trace("Hands Free Profile not found");
                        else
                        {
                            // Check device connection status.
                            Boolean Connected;
                            Res = Radio.GetRemoteConnectedStatus(Address, out Connected);
                            if (Res != wclErrors.WCL_E_SUCCESS)
                                Trace("Get connected status failed", Res);
                            else
                            {
                                // If connected - disconnect
                                if (Connected)
                                {
                                    Res = Radio.RemoteDisconnect(Address);
                                    if (Res != wclErrors.WCL_E_SUCCESS)
                                        Trace("Disconnect failed", Res);
                                }

                                if (Res == wclErrors.WCL_E_SUCCESS)
                                {
                                    // Check pairing status.
                                    Boolean Paired;
                                    Res = Radio.GetRemotePaired(Address, out Paired);
                                    if (Res != wclErrors.WCL_E_SUCCESS)
                                        Trace("Get paired status failed", Res);
                                    else
                                    {
                                        // We have to unpair the device!
                                        if (Paired)
                                        {
                                            Res = Radio.RemoteUnpair(Address);
                                            if (Res != wclErrors.WCL_E_SUCCESS)
                                                Trace("Unpair failed", Res);
                                        }

                                        if (Res == wclErrors.WCL_E_SUCCESS)
                                        {
                                            // Now start pairing
                                            FAddress = Address;
                                            Res = Radio.RemotePair(Address, wclBluetoothPairingMethod.pmClassic);
                                            if (Res != wclErrors.WCL_E_SUCCESS)
                                            {
                                                Trace("Start pairing failed", Res);
                                                FAddress = 0;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        private void btDisconnect_Click(Object sender, EventArgs e)
        {
            Int32 Res = FClient.Disconnect();
            if (Res != wclErrors.WCL_E_SUCCESS)
                Trace("Disconnect failed", Res);
        }
    }
}
