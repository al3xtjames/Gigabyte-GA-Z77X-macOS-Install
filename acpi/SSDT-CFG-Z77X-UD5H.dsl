DefinitionBlock ("SSDT-CFG.aml", "SSDT", 1, "APPLE ", "Config", 0x00001000)
{
	External (_SB_.PCI0, DeviceObj)

	External (_SB_.PCI0.B0D4, DeviceObj)
	External (_SB_.PCI0.ETH1, DeviceObj)
	External (_SB_.PCI0.LPCB, DeviceObj)
	External (_SB_.PCI0.LPCB.CWDT._STA, IntObj)
	External (_SB_.PCI0.LPCB.RMSC, DeviceObj)
	External (_SB_.PCI0.LPCB.SIO1, DeviceObj)
	External (_SB_.PCI0.PEG2, DeviceObj)
	External (_SB_.PCI0.PEG2.MVL3, DeviceObj)
	External (_SB_.PCI0.PEG2.MVL4, DeviceObj)
	External (_SB_.PCI0.RP02, DeviceObj)
	External (_SB_.PCI0.RP02.PXSX, DeviceObj)
	External (_SB_.PCI0.RP05, DeviceObj)
	External (_SB_.PCI0.RP05.MVL1, DeviceObj)
	External (_SB_.PCI0.RP05.MVL2, DeviceObj)
	External (_SB_.PCI0.RP05.PXSX, DeviceObj)
	External (_SB_.PCI0.RP06, DeviceObj)
	External (_SB_.PCI0.RP06.PXSX, DeviceObj)
	External (_SB_.PCI0.RP07, DeviceObj)
	External (_SB_.PCI0.RP07.PXSX, DeviceObj)
	External (_SB_.PCI0.RP08, DeviceObj)
	External (_SB_.PCI0.RP08.PXSX, DeviceObj)
	External (_SB_.PCI0.SAT1, DeviceObj)
	External (_SB_.PCI0.TPMX._STA, IntObj)
	External (_SB_.PCI0.USB1, DeviceObj)
	External (_SB_.PCI0.USB2, DeviceObj)
	External (_SB_.PCI0.USB3, DeviceObj)
	External (_SB_.PCI0.USB4, DeviceObj)
	External (_SB_.PCI0.USB5, DeviceObj)
	External (_SB_.PCI0.USB6, DeviceObj)
	External (_SB_.PCI0.USB7, DeviceObj)
	External (_SB_.PCI0.WMI1, DeviceObj)

	External (_SB_.PWRB, DeviceObj)

	External (_TZ_.FAN0, DeviceObj)
	External (_TZ_.FAN1, DeviceObj)
	External (_TZ_.FAN2, DeviceObj)
	External (_TZ_.FAN3, DeviceObj)
	External (_TZ_.FAN4, DeviceObj)

	External (_TZ_.TZ00, PkgObj)
	External (_TZ_.TZ01, PkgObj)

	Method (\_SB._INI, 0, NotSerialized) // _INI: Initialize
	{
		\_SB.PCI0.TPMX._STA = Zero
		\_SB.PCI0.LPCB.CWDT._STA = Zero
		\_TZ.TZ00 = Package (Zero) {}
		\_TZ.TZ01 = Package (Zero) {}
	}

	Scope (\_SB.PCI0)
	{
		Name (PW94, Package (0x02)
		{
			0x09,
			0x04
		})

		Scope (B0D4)
		{
			Name (_STA, Zero) // _STA: Status
		}

		Scope (ETH1)
		{
			Name (ETHP, Package (0x02) // Ethernet device properties
			{
				"location",
				Buffer (0x02)
				{
					"2"
				}
			})

			Method (_DSM, 4, NotSerialized) // _DSM: Device-Specific Method
			{
				If (!Arg2)
				{
					Return (Buffer (One)
					{
						0x03
					})
				}

				Return (RefOf (ETHP))
			}
		}

		Scope (RP02)
		{
			Scope (PXSX)
			{
				Name (_STA, Zero) // _STA: Status
			}

			Device (SATA)
			{
				Name (_ADR, Zero) // _ADR: Address
				Alias (PW94, _PRW) // _PRW: Power Resources for Wake
			}
		}

		Scope (RP05)
		{
			Scope (MVL1)
			{
				Name (_STA, Zero) // _STA: Status
			}

			Scope (MVL2)
			{
				Name (_STA, Zero) // _STA: Status
			}

			Scope (PXSX)
			{
				Name (_STA, Zero) // _STA: Status
			}

			Device (ARPT)
			{
				Name (_ADR, Zero) // _ADR: Address
				Alias (PW94, _PRW) // _PRW: Power Resources for Wake
			}
		}

		Scope (RP06)
		{
			Scope (PXSX)
			{
				Name (_STA, Zero) // _STA: Status
			}

			Device (FWBR)
			{
				Name (_ADR, Zero) // _ADR: Address
				Alias (PW94, _PRW) // _PRW: Power Resources for Wake
				Device (FRWR)
				{
					Name (_ADR, 0x06010000) // _ADR: Address
					Name (_GPE, 0x1A) // _GPE: General Purpose Events
					Method (_DSM, 4, NotSerialized) // _DSM: Device-Specific Method
					{
						If (!Arg2)
						{
							Return (Buffer (One)
							{
								0x03
							})
						}

						Return (Package (0x04)
						{
							"fwports",
							Buffer (0x04)
							{
								0x02, 0x00, 0x00, 0x00
							},

							"fws0",
							Buffer (0x04)
							{
								0x01, 0x00, 0x00, 0x00
							}
						})
					}
				}
			}

			Method (\_SB._GPE._L1A, 0, NotSerialized) // _Lxx: Level-Triggered GPE
			{
				Notify (\_SB.PCI0.RP06.FWBR.FRWR, 0x02) // Device Wake
				Notify (\_SB.PWRB, 0x02) // Device Wake
			}
		}

		Scope (RP07)
		{
			Scope (PXSX)
			{
				Name (_STA, Zero) // _STA: Status
			}

			Device (ETH0)
			{
				Name (_ADR, Zero) // _ADR: Address
				Alias (PW94, _PRW) // _PRW: Power Resources for Wake
				Method (_DSM, 4, NotSerialized) // _DSM: Device-Specific Method
				{
					If (!Arg2)
					{
						Return (Buffer (One)
						{
							0x03
						})
					}

					// Set location to 1 for ETH0
					^^^ETH1.ETHP [One] = Buffer (0x02) { "1" }
					// Return pointer to Ethernet device properties
					Return (RefOf (^^^ETH1.ETHP))
				}
			}
		}

		Scope (RP08)
		{
			Scope (PXSX)
			{
				Name (_STA, Zero) // _STA: Status
			}

			Device (SATA)
			{
				Name (_ADR, Zero) // _ADR: Address
				Alias (PW94, _PRW) // _PRW: Power Resources for Wake
			}
		}

		Scope (LPCB)
		{
			Scope (RMSC)
			{
				Name (_STA, Zero) // _STA: Status
			}

			Scope (SIO1)
			{
				Name (_STA, Zero) // _STA: Status
			}
		}

		Scope (PEG2)
		{
			Scope (MVL3)
			{
				Name (_STA, Zero) // _STA: Status
			}

			Scope (MVL4)
			{
				Name (_STA, Zero) // _STA: Status
			}
		}

		Scope (SAT1)
		{
			Name (_STA, Zero) // _STA: Status
		}

		Scope (USB1)
		{
			Name (_STA, Zero) // _STA: Status
		}

		Scope (USB2)
		{
			Name (_STA, Zero) // _STA: Status
		}

		Scope (USB3)
		{
			Name (_STA, Zero) // _STA: Status
		}

		Scope (USB4)
		{
			Name (_STA, Zero) // _STA: Status
		}

		Scope (USB5)
		{
			Name (_STA, Zero) // _STA: Status
		}

		Scope (USB6)
		{
			Name (_STA, Zero) // _STA: Status
		}

		Scope (USB7)
		{
			Name (_STA, Zero) // _STA: Status
		}

		Scope (WMI1)
		{
			Name (_STA, Zero) // _STA: Status
		}
	}

	Scope (\_TZ)
	{
		Scope (FAN0)
		{
			Name (_STA, Zero) // _STA: Status
		}

		Scope (FAN1)
		{
			Name (_STA, Zero) // _STA: Status
		}

		Scope (FAN2)
		{
			Name (_STA, Zero) // _STA: Status
		}

		Scope (FAN3)
		{
			Name (_STA, Zero) // _STA: Status
		}

		Scope (FAN4)
		{
			Name (_STA, Zero) // _STA: Status
		}
	}
}
