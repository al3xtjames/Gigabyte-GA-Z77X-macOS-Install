DefinitionBlock ("SSDT-PEG.aml", "SSDT", 1, "APPLE ", "PcieGfx", 0x00001000)
{

    External (_SB_.PCI0.PEG0, DeviceObj)
    External (_SB_.PCI0.PEG0.GFX0, DeviceObj)

    Scope (\_SB.PCI0.PEG0)
    {
        Scope (GFX0)
        {
            OperationRegion (PEGH, PCI_Config, Zero, 0x14)
            Field (PEGH, AnyAcc, NoLock, Preserve)
            {
                VID,	16 // PCIe GPU Device ID
            }

            Method (_DSM, 4, NotSerialized) // _DSM: Device-Specific Method
            {
                If (!Arg2)
                {
                    Return (Buffer (One)
                    {
                        0x03
                    })
                }

                // Enable PCIe HDMI audio
                Return (Package (0x04)
                {
                    "AAPL,slot-name",
                    Buffer (0x07)
                    {
                        "Slot-1"
                    },

                    "hda-gfx",
                    Buffer (0x0A)
                    {
                        "onboard-1"
                    }
                })
            }
        }

        Device (HDAU)
        {
            Name (_ADR, One) // _ADR: Address
        }
    }
}
