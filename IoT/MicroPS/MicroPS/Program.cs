using System;
using System.Device.Gpio;
using System.Diagnostics;
using System.IO.Ports;
using System.Threading;
using nanoFramework.Hardware.Esp32;

namespace MicroPS
{
    public class Program
    {
        private const int OnboardLedPin = 15;
        private const int ApplicationUartTxPin = 16;
        private const int ApplicationUartRxPin = 17;
        private const int BlinkIntervalMilliseconds = 500;
        private const int BaudRate = 115200;

        private static readonly object s_ledSync = new object();
        private static GpioController s_gpioController;
        private static GpioPin s_led;
        private static SerialPort s_serialPort;
        private static Thread s_blinkThread;
        private static LedMode s_mode = LedMode.Blink;
        private static bool s_ledIsOn;

        private enum LedMode
        {
            Off,
            On,
            Blink
        }

        public static void Main()
        {
            InitializeLed();
            InitializeSerialPort();

            s_blinkThread = new Thread(BlinkWorker);
            s_blinkThread.Start();

            uint freeManagedHeap = nanoFramework.Runtime.Native.GC.Run(true);
            WriteResponse("MICROPS READY");
            WriteResponse("FREE MANAGED HEAP: " + freeManagedHeap.ToString() + " BYTES");

            while (true)
            {
                ProcessCommand(s_serialPort.ReadLine());
            }
        }

        private static void InitializeLed()
        {
            s_gpioController = new GpioController();
            s_led = s_gpioController.OpenPin(OnboardLedPin, PinMode.Output);
            SetMode(LedMode.Blink);
        }

        private static void InitializeSerialPort()
        {
            Configuration.SetPinFunction(ApplicationUartTxPin, DeviceFunction.COM2_TX);
            Configuration.SetPinFunction(ApplicationUartRxPin, DeviceFunction.COM2_RX);

            s_serialPort = new SerialPort("COM2", BaudRate)
            {
                DataBits = 8,
                Handshake = Handshake.None,
                NewLine = "\n",
                Parity = Parity.None,
                StopBits = StopBits.One,
                WriteTimeout = 1000
            };
            s_serialPort.Open();
        }

        private static void ProcessCommand(string command)
        {
            string normalizedCommand = command.Trim().ToUpper();

            switch (normalizedCommand)
            {
                case "ON":
                    SetMode(LedMode.On);
                    WriteResponse("OK ON");
                    break;

                case "OFF":
                    SetMode(LedMode.Off);
                    WriteResponse("OK OFF");
                    break;

                case "BLINK":
                    SetMode(LedMode.Blink);
                    WriteResponse("OK BLINK");
                    break;

                default:
                    WriteResponse("ERR UNKNOWN");
                    break;
            }
        }

        private static void SetMode(LedMode mode)
        {
            lock (s_ledSync)
            {
                s_mode = mode;

                switch (mode)
                {
                    case LedMode.On:
                    case LedMode.Blink:
                        WriteLed(true);
                        break;

                    default:
                        WriteLed(false);
                        break;
                }
            }
        }

        private static void BlinkWorker()
        {
            while (true)
            {
                Thread.Sleep(BlinkIntervalMilliseconds);

                lock (s_ledSync)
                {
                    if (s_mode == LedMode.Blink)
                    {
                        WriteLed(!s_ledIsOn);
                    }
                }
            }
        }

        private static void WriteLed(bool isOn)
        {
            s_led.Write(isOn ? PinValue.Low : PinValue.High);
            s_ledIsOn = isOn;
        }

        private static void WriteResponse(string response)
        {
            Debug.WriteLine(response);
            s_serialPort.WriteLine(response);
        }
    }
}
