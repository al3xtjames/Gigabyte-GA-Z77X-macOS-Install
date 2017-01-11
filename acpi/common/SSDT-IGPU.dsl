DefinitionBlock ("SSDT-IGPU.aml", "SSDT", 1, "APPLE ", "IGNoHda", 0x00001000)
{

	External (_SB_.PCI0, DeviceObj)
	External (_SB_.PCI0.IGPU, DeviceObj)
	External (_SB_.PCI0.IMEI, DeviceObj)
	External (_SB_.PCI0.PEG0.GFX0.VID_, FieldUnitObj)

	Scope (\_SB.PCI0)
	{
		Scope (IGPU)
		{
			OperationRegion (IGPH, PCI_Config, Zero, 0x14)
			Field (IGPH, AnyAcc, NoLock, Preserve)
			{
				Offset (0x02),
				DID,	16 // IGPU Device ID
			}

			// IGPU primary device properties
			Name (IGPP, Package (0x0D)
			{
				0x0112,
				0x0122,
				Zero,
				Package (0x08)
				{
					"device-id",
					Buffer (0x04)
					{
						0x26, 0x01, 0x00, 0x00
					},

					"AAPL,snb-platform-id",
					Buffer (0x04)
					{
						0x10, 0x00, 0x03, 0x00
					},

					"model",
					Buffer (0x17)
					{
						"Intel HD Graphics 3000"
					},

					"hda-gfx",
					Buffer (0x0A)
					{
						"onboard-1"
					}
				},

				0x010A,
				Zero,
				Package (0x08)
				{
					"device-id",
					Buffer (0x04)
					{
						0x26, 0x01, 0x00, 0x00
					},

					"AAPL,snb-platform-id",
					Buffer (0x04)
					{
						0x10, 0x00, 0x03, 0x00
					},

					"model",
					Buffer (0x18)
					{
						"Intel HD Graphics P3000"
					},

					"hda-gfx",
					Buffer (0x0A)
					{
						"onboard-1"
					}
				},

				0x0162,
				Zero,
				Package (0x04)
				{
					"AAPL,ig-platform-id",
					Buffer (0x04)
					{
						0x05, 0x00, 0x62, 0x01
					},

					"hda-gfx",
					Buffer (0x0A)
					{
						"onboard-1"
					}
				},

				0x016A,
				Zero,
				Package (0x08)
				{
					"device-id",
					Buffer (0x04)
					{
						0x62, 0x01, 0x00, 0x00
					},

					"AAPL,ig-platform-id",
					Buffer (0x04)
					{
						0x05, 0x00, 0x62, 0x01
					},

					"model",
					Buffer (0x18)
					{
						"Intel HD Graphics P4000"
					},

					"hda-gfx",
					Buffer (0x0A)
					{
						"onboard-1"
					}
				}
			})

			// IGPU secondary device properties
			Name (IGSP, Package (0x13)
			{
				0x0102,
				Zero,
				Package (0x04)
				{
					"AAPL,snb-platform-id",
					Buffer (0x04)
					{
						0x01, 0x00, 0x03, 0x00
					},

					"model",
					Buffer (0x17)
					{
						"Intel HD Graphics 2000"
					}
				},

				0x0112,
				0x0122,
				Zero,
				Package (0x06)
				{
					"device-id",
					Buffer (0x04)
					{
						0x26, 0x01, 0x00, 0x00
					},

					"AAPL,snb-platform-id",
					Buffer (0x04)
					{
						0x01, 0x00, 0x03, 0x00
					},

					"model",
					Buffer (0x17)
					{
						"Intel HD Graphics 3000"
					}
				},

				0x010A,
				Zero,
				Package (0x06)
				{
					"device-id",
					Buffer (0x04)
					{
						0x26, 0x01, 0x00, 0x00
					},

					"AAPL,snb-platform-id",
					Buffer (0x04)
					{
						0x01, 0x00, 0x03, 0x00
					},

					"model",
					Buffer (0x18)
					{
						"Intel HD Graphics P3000"
					}
				},

				0x0152,
				Zero,
				Package (0x04)
				{
					"AAPL,ig-platform-id",
					Buffer (0x04)
					{
						0x07, 0x00, 0x62, 0x01
					},

					"model",
					Buffer (0x17)
					{
						"Intel HD Graphics 2500"
					}
				},

				0x0162,
				Zero,
				Package (0x02)
				{
					"AAPL,ig-platform-id",
					Buffer (0x04)
					{
						0x07, 0x00, 0x62, 0x01
					}
				},

				0x016A,
				Zero,
				Package (0x04)
				{
					"AAPL,ig-platform-id",
					Buffer (0x04)
					{
						0x07, 0x00, 0x62, 0x01
					},

					"model",
					Buffer (0x18)
					{
						"Intel HD Graphics P4000"
					}
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

				// Check GFX0.VID to determine primary display adapter
				Local0 = Ones
				If ((^^PEG0.GFX0.VID == 0x8086))
				{
					// IGPU is primary, use IGPU primary device properties
					Local0 = IGPP
				}
				Else
				{
					// PCIe is primary, use IGPU secondary device properties
					Local0 = IGSP
				}

				// Return proper IGPU device properties (based off device ID)
				Local1 = Match (Local0, MEQ, DID, MTR, Zero, Zero)
				If ((Ones != Local1))
				{
					Local1 = Match (Local0, MEQ, Zero, MTR, Zero, (Local1 + One))
					Return (DerefOf (Local0 [(Local1 + One)]))
				}

				Return (Package (Zero) {})
			}
		}

		Scope (IMEI)
		{
			Method (_DSM, 4, NotSerialized) // _DSM: Device-Specific Method
			{
				If (!Arg2)
				{
					Return (Buffer (One)
					{
						0x03
					})
				}

				// Set device-id to 0x1C3A for Sandy Bridge IGPUs
				If ((((^^IGPU.DID == 0x0102) || (^^IGPU.DID == 0x0112)) || ((^^IGPU.DID == 0x0122) | (^^IGPU.DID == 0x010A))))
				{
					Return (Package (0x02)
					{
						"device-id",
						Buffer (0x04)
						{
							0x3A, 0x1C, 0x00, 0x00
						}
					})
				}

				Return (Package (Zero) {})
			}
		}
	}
}
