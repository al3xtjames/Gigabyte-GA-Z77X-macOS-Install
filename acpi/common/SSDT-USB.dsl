DefinitionBlock ("SSDT-USB.aml", "SSDT", 1, "APPLE ", "UsbPpt", 0x00001000)
{

	External (_SB_.PCI0, DeviceObj)
	External (_SB_.PCI0.EHC1, DeviceObj)
	External (_SB_.PCI0.EHC2, DeviceObj)
	External (_SB_.PCI0.XHC1, DeviceObj)

	Scope (\_SB.PCI0)
	{
		Scope (EHC1)
		{
			Name (MBSD, One) // Enable USB SuperDrive support
			Method (_DSM, 4, NotSerialized) // _DSM: Device-Specific Method
			{
				If (!Arg2)
				{
					Return (Buffer (One)
					{
						0x03
					})
				}

				// Return pointer to USB device properties
				Return (RefOf (^^XHC1.USBP))
			}
		}

		Scope (EHC2)
		{
			Name (MBSD, One) // Enable USB SuperDrive support
			Method (_DSM, 4, NotSerialized) // _DSM: Device-Specific Method
			{
				If (!Arg2)
				{
					Return (Buffer (One)
					{
						0x03
					})
				}

				// Return pointer to USB device properties
				Return (RefOf (^^XHC1.USBP))
			}
		}

		Scope (XHC1)
		{
			Name (MBSD, One) // Enable USB SuperDrive support
			Name (USBP, Package (0x0A) // USB device properties
			{
				"AAPL,current-available",
				0x0834,
				"AAPL,current-extra",
				0x0A8C,
				"AAPL,current-extra-in-sleep",
				0x0A8C,
				"AAPL,device-internal",
				0x02,
				"AAPL,max-port-current-in-sleep",
				0x0834
			})

			Method (_DSM, 4, NotSerialized)  // _DSM: Device-Specific Method
			{
				If (!Arg2)
				{
					Return (Buffer (One)
					{
						0x03
					})
				}

				// Set AAPL,device-internal to Zero for XHC1
				USBP [0x07] = Zero
				// Return pointer to USB device properties
				Return (RefOf (USBP))
			}
		}
	}
}
