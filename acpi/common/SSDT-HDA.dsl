DefinitionBlock ("SSDT-HDA.aml", "SSDT", 1, "APPLE ", "Hda", 0x00001000)
{

	External (_SB_.PCI0.HDEF, DeviceObj)
	External (_SB_.PCI0.PEG0.GFX0.VID_, FieldUnitObj)

	Scope (\_SB.PCI0.HDEF)
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

			// Enable Intel HDMI audio if IGPU is primary
			If ((^^PEG0.GFX0.VID == 0x8086))
			{
				Return (Package (0x02)
				{
					"hda-gfx",
					Buffer (0x0A)
					{
						"onboard-1"
					}
				})
			}

			Return (Package (Zero) {})
		}
	}
}
