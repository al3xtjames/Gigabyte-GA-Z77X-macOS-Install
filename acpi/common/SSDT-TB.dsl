DefinitionBlock ("SSDT-PcieTbt.aml", "SSDT", 2, "Apple", "PcieTbt", 0x00001000)
{
    External (_SB_.PCI0, DeviceObj)
    External (_SB_.PCI0.RP01, DeviceObj)

    External (GD04, FieldUnitObj)
    External (GD24, FieldUnitObj)
    External (GI04, FieldUnitObj)
    External (GP04, FieldUnitObj)
    External (GP23, FieldUnitObj)
    External (GP24, FieldUnitObj)
    External (GP36, FieldUnitObj)

    OperationRegion (BDAR, SystemMemory, 0x04F1, One)
    Field (BDAR, ByteAcc, NoLock, Preserve)
    {
        ISTB,   1,
        Offset (0x01)
    }

    Scope (\_SB.PCI0)
    {
        Method (DTBP, 0, Serialized)
        {
            If ((\_SB.PCI0.RP01.LDIS == Zero))
            {
                Return (One)
            }

            Return (Zero)
        }

        Name (EJCD, Zero)
        Name (TBBT, Zero)
        Method (RMC1, 0, Serialized)
        {
            Debug = "RMCR: Disable Link and Power Off Cactus Ridge Chip"
            \_SB.PCI0.RP01.LDIS = One
            Sleep (0x07D0)
            GP23 = Zero
        }

        Method (DTLK, 0, Serialized)
        {
            Debug = "DTLK: Dsiable Link and Power off CR going into S4/S5"
            \_SB.PCI0.RP01.LDIS = One
            Sleep (0x07D0)
            GP23 = Zero
        }

        Scope (RP01)
        {
            OperationRegion (A1E0, PCI_Config, Zero, 0x40)
            Field (A1E0, ByteAcc, NoLock, Preserve)
            {
                AVND,   32,
                BMIE,   3,
                Offset (0x18),
                PRIB,   8,
                SECB,   8,
                SUBB,   8,
                Offset (0x1E),
                    ,   13,
                MABT,   1
            }

            OperationRegion (A1E1, PCI_Config, 0x40, 0x40)
            Field (A1E1, ByteAcc, NoLock, Preserve)
            {
                Offset (0x01),
                Offset (0x02),
                Offset (0x04),
                Offset (0x08),
                Offset (0x0A),
                    ,	5,
                TPEN,	1,
                Offset (0x0C),
                SSPD,	4,
                    ,	16,
                LACR,	1,
                Offset (0x10),
                    ,	4,
                LDIS,	1,
                LRTN,	1,
                Offset (0x12),
                CSPD,	4,
                    ,	7,
                LTRN,	1,
                    ,	1,
                LACT,	1,
                Offset (0x14),
                Offset (0x30),
                TSPD,	4
            }

            OperationRegion (A1E2, PCI_Config, 0xA0, 0x08)
            Field (A1E2, ByteAcc, NoLock, Preserve)
            {
                Offset (0x01),
                Offset (0x02),
                Offset (0x04),
                PSTA,	2
            }

            OperationRegion (A1E3, PCI_Config, 0x0200, 0x20)
            Field (A1E3, ByteAcc, NoLock, Preserve)
            {
                Offset (0x14),
                Offset (0x16),
                PSTS,	4
            }

            Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
            {
                Return (Zero)
            }

            Device (UPSB)
            {
                Name (_ADR, Zero)  // _ADR: Address
                OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                Field (A1E0, ByteAcc, NoLock, Preserve)
                {
                    AVND,	32,
                    BMIE,	3,
                    Offset (0x18),
                    PRIB,	8,
                    SECB,	8,
                    SUBB,	8,
                    Offset (0x1E),
                        ,	13,
                    MABT,	1
                }

                OperationRegion (A1E1, PCI_Config, 0xC0, 0x40)
                Field (A1E1, ByteAcc, NoLock, Preserve)
                {
                    Offset (0x01),
                    Offset (0x02),
                    Offset (0x04),
                    Offset (0x08),
                    Offset (0x0A),
                        ,	5,
                    TPEN,	1,
                    Offset (0x0C),
                    SSPD,	4,
                    Offset (0x10),
                        ,	4,
                    LDIS,	1,
                    LRTN,	1,
                        ,	23,
                    LACT,	1,
                    Offset (0x30),
                    TSPD,	4
                }

                OperationRegion (A1E2, PCI_Config, 0x80, 0x08)
                Field (A1E2, ByteAcc, NoLock, Preserve)
                {
                    Offset (0x01),
                    Offset (0x02),
                    Offset (0x04),
                    PSTA,	2
                }

                Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                {
                    Return (SECB)
                }

                Method (_STA, 0, NotSerialized)  // _STA: Status
                {
                    Return (0x0F)
                }

                Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                {
                    Return (Zero)
                }

                Device (DSB0)
                {
                    Name (_ADR, Zero)  // _ADR: Address
                    OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                    Field (A1E0, ByteAcc, NoLock, Preserve)
                    {
                        AVND,	32,
                        BMIE,	3,
                        Offset (0x18),
                        PRIB,	8,
                        SECB,	8,
                        SUBB,	8,
                        Offset (0x1E),
                            ,	13,
                        MABT,	1
                    }

                    OperationRegion (A1E1, PCI_Config, 0xC0, 0x40)
                    Field (A1E1, ByteAcc, NoLock, Preserve)
                    {
                        Offset (0x01),
                        Offset (0x02),
                        Offset (0x04),
                        Offset (0x08),
                        Offset (0x0A),
                            ,	5,
                        TPEN,	1,
                        Offset (0x0C),
                        Offset (0x10),
                            ,	4,
                        LDIS,	1,
                        LRTN,	1,
                            ,	23,
                        LACT,	1
                    }

                    OperationRegion (A1E2, PCI_Config, 0x80, 0x08)
                    Field (A1E2, ByteAcc, NoLock, Preserve)
                    {
                        Offset (0x01),
                        Offset (0x02),
                        Offset (0x04),
                        PSTA,	2
                    }

                    Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                    {
                        Return (SECB)
                    }

                    Method (_STA, 0, NotSerialized)  // _STA: Status
                    {
                        Return (0x0F)
                    }

                    Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                    {
                        Return (Zero)
                    }

                    Device (NHI0)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (_STR, Unicode ("Thunderbolt"))  // _STR: Description String
                        Name (_GPE, 0x14)  // _GPE: General Purpose Events
                        OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                        Field (A1E0, ByteAcc, NoLock, Preserve)
                        {
                            AVND,	32,
                            BMIE,	3,
                            Offset (0x18),
                            PRIB,	8,
                            SECB,	8,
                            SUBB,	8,
                            Offset (0x1E),
                                ,	13,
                            MABT,	1
                        }

                        Method (XDPG, 0, NotSerialized)
                        {
                            Return (GP36)
                        }

                        Method (XDPS, 1, Serialized)
                        {
                            If ((Arg0 <= One))
                            {
                                GP36 = Arg0
                            }
                        }

                        Method (XRPE, 1, Serialized)
                        {
                            If ((Arg0 <= One))
                            {
                                If ((Arg0 == Zero))
                                {
                                    \_SB.PCI0.RP01.PSTA = 0x03
                                    \_SB.PCI0.RP01.LDIS = One
                                    Local0 = (Timer + 0x00989680)
                                    While ((Timer <= Local0))
                                    {
                                        If ((\_SB.PCI0.RP01.LACR == One))
                                        {
                                            If ((\_SB.PCI0.RP01.LACT == Zero))
                                            {
                                                Break
                                            }
                                        }
                                        ElseIf ((\_SB.PCI0.RP01.UPSB.AVND == 0xFFFFFFFF))
                                        {
                                            Break
                                        }

                                        Sleep (0x0A)
                                    }

                                    GP23 = Zero
                                }
                                Else
                                {
                                    Local0 = Zero
                                    If ((GP23 == Zero))
                                    {
                                        \_SB.PCI0.RP01.PSTA = Zero
                                        While (One)
                                        {
                                            GP23 = One
                                            Local1 = Zero
                                            Local2 = (Timer + 0x00989680)
                                            While ((Timer <= Local2))
                                            {
                                                If (((\_SB.PCI0.RP01.LTRN != One) && (\_SB.PCI0.RP01.UPSB.AVND != 0xFFFFFFFF)))
                                                {
                                                    Break
                                                }

                                                Sleep (0x0A)
                                            }

                                            \_SB.PCI0.RP01.LDIS = Zero
                                            Local2 = (Timer + 0x00989680)
                                            While ((Timer <= Local2))
                                            {
                                                If (((\_SB.PCI0.RP01.LTRN != One) && (\_SB.PCI0.RP01.UPSB.AVND != 0xFFFFFFFF)))
                                                {
                                                    Local1 = One
                                                    Break
                                                }

                                                Sleep (0x0A)
                                            }

                                            If ((Local1 == One))
                                            {
                                                MABT = One
                                                Break
                                            }

                                            If ((Local0 == 0x04))
                                            {
                                                Return (Zero)
                                            }

                                            Local0++
                                            GP23 = Zero
                                            Sleep (0x03E8)
                                        }

                                        If ((\_SB.PCI0.RP01.CSPD == One))
                                        {
                                            If ((\_SB.PCI0.RP01.SSPD == 0x02))
                                            {
                                                If ((\_SB.PCI0.RP01.UPSB.SSPD == 0x02))
                                                {
                                                    If ((\_SB.PCI0.RP01.TSPD != 0x02))
                                                    {
                                                        \_SB.PCI0.RP01.TSPD = 0x02
                                                    }

                                                    If ((\_SB.PCI0.RP01.UPSB.TSPD != 0x02))
                                                    {
                                                        \_SB.PCI0.RP01.UPSB.TSPD = 0x02
                                                    }

                                                    \_SB.PCI0.RP01.LRTN = One
                                                    Local2 = (Timer + 0x00989680)
                                                    While ((Timer <= Local2))
                                                    {
                                                        If (((\_SB.PCI0.RP01.LTRN != One) && (\_SB.PCI0.RP01.UPSB.AVND != 0xFFFFFFFF)))
                                                        {
                                                            Local1 = One
                                                            Break
                                                        }

                                                        Sleep (0x0A)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Return (Zero)
                        }

                        Method (XRIP, 1, Serialized)
                        {
                            If ((Arg0 <= One))
                            {
                                GI04 = Arg0
                            }
                        }

                        Method (XRIO, 1, Serialized)
                        {
                            If ((Arg0 <= One))
                            {
                                GD04 = Arg0
                            }
                        }

                        Method (XRIL, 0, Serialized)
                        {
                            Return (GP04)
                        }

                        Name (XRIN, 0x14)
                        Method (_DSM, 4, NotSerialized)  // _DSM: Device-Specific Method
                        {
                            If (!Arg2)
                            {
                                Return (Buffer (One)
                                {
                                    0x03
                                })
                            }

                            Return (Package (0x0C)
                            {
                                "pathcr", Buffer (0x50)
                                {
                                    0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x07, 0x00, 0x10, 0x00, 0x10, 0x00,
                                    0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x07, 0x00, 0x10, 0x00, 0x10, 0x00,
                                    0x01, 0x00, 0x00, 0x00, 0x0B, 0x00, 0x0E, 0x00,
                                    0x0E, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                    0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x04, 0x00, 0x02, 0x00, 0x01, 0x00,
                                    0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x07, 0x00, 0x02, 0x00, 0x01, 0x00
                                },

                                // Only one that's present in real Mac's ACPI tables
                                // Rest are EFI device properties
                                "power-save",
                                One,

                                "sscOffset", Buffer (0x02)
                                {
                                    0x00, 0x07
                                },

                                "TBTDPLowToHigh", Buffer (0x04)
                                {
                                    0x01, 0x00, 0x00, 0x00
                                },

                                "ThunderboltDROM", Buffer (0x100)
                                {
                                    0x28, 0x60, 0xEE, 0xF4, 0x16, 0x0D, 0x00, 0x01,
                                    0x00, 0xBC, 0x8F, 0xB7, 0x3E, 0x01, 0x65, 0x00,
                                    0x01, 0x00, 0x0A, 0x00, 0x01, 0x02, 0x08, 0x81,
                                    0x80, 0x02, 0x80, 0x00, 0x00, 0x00, 0x08, 0x82,
                                    0x90, 0x01, 0x80, 0x00, 0x00, 0x00, 0x08, 0x83,
                                    0x80, 0x04, 0x80, 0x01, 0x00, 0x00, 0x08, 0x84,
                                    0x90, 0x03, 0x80, 0x01, 0x00, 0x00, 0x08, 0x85,
                                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0x86,
                                    0x60, 0x03, 0x87, 0x80, 0x03, 0x88, 0xA0, 0x03,
                                    0x89, 0xC0, 0x05, 0x8A, 0x50, 0x00, 0x00, 0x05,
                                    0x8B, 0x50, 0x00, 0x82, 0x05, 0x8C, 0x50, 0x00,
                                    0x84, 0x0D, 0x01, 0x41, 0x70, 0x70, 0x6C, 0x65,
                                    0x20, 0x49, 0x6E, 0x63, 0x2E, 0x00, 0x0C, 0x02,
                                    0x4D, 0x61, 0x63, 0x69, 0x6E, 0x74, 0x6F, 0x73,
                                    0x68, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
                                },

                                "ThunderboltUUID", Buffer (0x10)
                                {
                                    0xE3, 0x42, 0xB1, 0x12, 0x8D, 0xBA, 0x6B, 0x57,
                                    0xAA, 0x14, 0xDE, 0x4F, 0xE0, 0x18, 0x72, 0xED
                                }
                            })
                        }

                        Method (SXIO, 1, Serialized)
                        {
                            If ((Arg0 <= One))
                            {
                                GD24 = Arg0
                            }
                        }

                        Method (SXIL, 0, Serialized)
                        {
                            Return (GP24) /* External reference */
                        }

                        Method (SXLV, 1, Serialized)
                        {
                            If ((Arg0 <= One))
                            {
                                GP24 = Arg0
                            }
                        }

                        Method (SXFP, 1, Serialized)
                        {
                            If ((Arg0 == Zero))
                            {
                                GP23 = Zero
                            }
                        }
                    }
                }

                Device (DSB1)
                {
                    Name (_ADR, 0x00030000)  // _ADR: Address
                    Name (_SUN, 0x02)  // _SUN: Slot User Number
                    OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                    Field (A1E0, ByteAcc, NoLock, Preserve)
                    {
                        AVND,   32,
                        BMIE,   3,
                        Offset (0x18),
                        PRIB,   8,
                        SECB,   8,
                        SUBB,   8,
                        Offset (0x1E),
                            ,   13,
                        MABT,   1
                    }

                    Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                    {
                        Return (SECB)
                    }

                    Method (_STA, 0, NotSerialized)  // _STA: Status
                    {
                        Return (0x0F)
                    }

                    Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                    {
                        Return (Zero)
                    }

                    Device (UPS0)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        OperationRegion (ARE0, PCI_Config, Zero, 0x04)
                        Field (ARE0, ByteAcc, NoLock, Preserve)
                        {
                            AVND,	16
                        }

                        Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                        {
                            Return (One)
                        }

                        Device (DSB0)
                        {
                            Name (_ADR, Zero)  // _ADR: Address
                            OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                            Field (A1E0, ByteAcc, NoLock, Preserve)
                            {
                                AVND,	32,
                                BMIE,	3,
                                Offset (0x18),
                                PRIB,	8,
                                SECB,	8,
                                SUBB,	8,
                                Offset (0x1E),
                                    ,	13,
                                MABT,	1,
                                Offset (0x3E),
                                    ,	6,
                                SBRS,	1
                            }

                            Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                            {
                                Return (SECB)
                            }

                            Method (_STA, 0, NotSerialized)  // _STA: Status
                            {
                                Return (0x0F)
                            }

                            Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                            {
                                Return (One)
                            }

                            Device (DEV0)
                            {
                                Name (_ADR, Zero)  // _ADR: Address
                                Method (_STA, 0, NotSerialized)  // _STA: Status
                                {
                                    Return (0x0F)
                                }

                                Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                {
                                    Return (One)
                                }
                            }
                        }

                        Device (DSB3)
                        {
                            Name (_ADR, 0x00030000)  // _ADR: Address
                            OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                            Field (A1E0, ByteAcc, NoLock, Preserve)
                            {
                                AVND,	32,
                                BMIE,	3,
                                Offset (0x18),
                                PRIB,	8,
                                SECB,	8,
                                SUBB,	8,
                                Offset (0x1E),
                                    ,	13,
                                MABT,	1
                            }

                            Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                            {
                                Return (SECB)
                            }

                            Method (_STA, 0, NotSerialized)  // _STA: Status
                            {
                                Return (0x0F)
                            }

                            Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                            {
                                Return (One)
                            }

                            Device (UPS0)
                            {
                                Name (_ADR, Zero)  // _ADR: Address
                                OperationRegion (ARE0, PCI_Config, Zero, 0x04)
                                Field (ARE0, ByteAcc, NoLock, Preserve)
                                {
                                    AVND,	16
                                }

                                Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                {
                                    Return (One)
                                }

                                Device (DSB0)
                                {
                                    Name (_ADR, Zero)  // _ADR: Address
                                    OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                                    Field (A1E0, ByteAcc, NoLock, Preserve)
                                    {
                                        AVND,	32,
                                        BMIE,	3,
                                        Offset (0x18),
                                        PRIB,	8,
                                        SECB,	8,
                                        SUBB,	8,
                                        Offset (0x1E),
                                            ,	13,
                                        MABT,	1,
                                        Offset (0x3E),
                                            ,	6,
                                        SBRS,	1
                                    }

                                    Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                                    {
                                        Return (SECB)
                                    }

                                    Method (_STA, 0, NotSerialized)  // _STA: Status
                                    {
                                        Return (0x0F)
                                    }

                                    Device (DEV0)
                                    {
                                        Name (_ADR, Zero)  // _ADR: Address
                                        Method (_STA, 0, NotSerialized)  // _STA: Status
                                        {
                                            Return (0x0F)
                                        }
                                    }
                                }

                                Device (DSB3)
                                {
                                    Name (_ADR, 0x00030000)  // _ADR: Address
                                    OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                                    Field (A1E0, ByteAcc, NoLock, Preserve)
                                    {
                                        AVND,	32,
                                        BMIE,	3,
                                        Offset (0x18),
                                        PRIB,	8,
                                        SECB,	8,
                                        SUBB,	8,
                                        Offset (0x1E),
                                            ,	13,
                                        MABT,	1
                                    }

                                    Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                                    {
                                        Return (SECB)
                                    }

                                    Method (_STA, 0, NotSerialized)  // _STA: Status
                                    {
                                        Return (0x0F)
                                    }

                                    Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                    {
                                        Return (One)
                                    }

                                    Device (DEV0)
                                    {
                                        Name (_ADR, Zero)  // _ADR: Address
                                        Method (_STA, 0, NotSerialized)  // _STA: Status
                                        {
                                            Return (0x0F)
                                        }

                                        Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                        {
                                            Return (One)
                                        }
                                    }
                                }

                                Device (DSB4)
                                {
                                    Name (_ADR, 0x00040000)  // _ADR: Address
                                    OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                                    Field (A1E0, ByteAcc, NoLock, Preserve)
                                    {
                                        AVND,   32,
                                        BMIE,   3,
                                        Offset (0x18),
                                        PRIB,   8,
                                        SECB,   8,
                                        SUBB,   8,
                                        Offset (0x1E),
                                            ,   13,
                                        MABT,   1
                                    }

                                    Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                                    {
                                        Return (SECB) /* \_SB_.PCI0.RP01.UPSB.DSB1.UPS0.DSB3.UPS0.DSB4.SECB */
                                    }

                                    Method (_STA, 0, NotSerialized)  // _STA: Status
                                    {
                                        Return (0x0F)
                                    }

                                    Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                    {
                                        Return (One)
                                    }

                                    Device (DEV0)
                                    {
                                        Name (_ADR, Zero)  // _ADR: Address
                                        Method (_STA, 0, NotSerialized)  // _STA: Status
                                        {
                                            Return (0x0F)
                                        }

                                        Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                        {
                                            Return (One)
                                        }
                                    }
                                }

                                Device (DSB5)
                                {
                                    Name (_ADR, 0x00050000)  // _ADR: Address
                                    OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                                    Field (A1E0, ByteAcc, NoLock, Preserve)
                                    {
                                        AVND,   32,
                                        BMIE,   3,
                                        Offset (0x18),
                                        PRIB,   8,
                                        SECB,   8,
                                        SUBB,   8,
                                        Offset (0x1E),
                                            ,   13,
                                        MABT,   1
                                    }

                                    Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                                    {
                                        Return (SECB) /* \_SB_.PCI0.RP01.UPSB.DSB1.UPS0.DSB3.UPS0.DSB5.SECB */
                                    }

                                    Method (_STA, 0, NotSerialized)  // _STA: Status
                                    {
                                        Return (0x0F)
                                    }

                                    Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                    {
                                        Return (One)
                                    }
                                }

                                Device (DSB6)
                                {
                                    Name (_ADR, 0x00060000)  // _ADR: Address
                                    OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                                    Field (A1E0, ByteAcc, NoLock, Preserve)
                                    {
                                        AVND,   32,
                                        BMIE,   3,
                                        Offset (0x18),
                                        PRIB,   8,
                                        SECB,   8,
                                        SUBB,   8,
                                        Offset (0x1E),
                                            ,   13,
                                        MABT,   1
                                    }

                                    Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                                    {
                                        Return (SECB) /* \_SB_.PCI0.RP01.UPSB.DSB1.UPS0.DSB3.UPS0.DSB6.SECB */
                                    }

                                    Method (_STA, 0, NotSerialized)  // _STA: Status
                                    {
                                        Return (0x0F)
                                    }

                                    Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                    {
                                        Return (One)
                                    }
                                }
                            }
                        }

                        Device (DSB4)
                        {
                            Name (_ADR, 0x00040000)  // _ADR: Address
                            OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                            Field (A1E0, ByteAcc, NoLock, Preserve)
                            {
                                AVND,   32,
                                BMIE,   3,
                                Offset (0x18),
                                PRIB,   8,
                                SECB,   8,
                                SUBB,   8,
                                Offset (0x1E),
                                    ,   13,
                                MABT,   1
                            }

                            Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                            {
                                Return (SECB) /* \_SB_.PCI0.RP01.UPSB.DSB1.UPS0.DSB4.SECB */
                            }

                            Method (_STA, 0, NotSerialized)  // _STA: Status
                            {
                                Return (0x0F)
                            }

                            Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                            {
                                Return (One)
                            }

                            Device (UPS0)
                            {
                                Name (_ADR, Zero)  // _ADR: Address
                                OperationRegion (ARE0, PCI_Config, Zero, 0x04)
                                Field (ARE0, ByteAcc, NoLock, Preserve)
                                {
                                    AVND,   16
                                }

                                Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                {
                                    Return (One)
                                }

                                Device (DSB0)
                                {
                                    Name (_ADR, Zero)  // _ADR: Address
                                    OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                                    Field (A1E0, ByteAcc, NoLock, Preserve)
                                    {
                                        AVND,   32,
                                        BMIE,   3,
                                        Offset (0x18),
                                        PRIB,   8,
                                        SECB,   8,
                                        SUBB,   8,
                                        Offset (0x1E),
                                            ,   13,
                                        MABT,   1,
                                        Offset (0x3E),
                                            ,   6,
                                        SBRS,   1
                                    }

                                    Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                                    {
                                        Return (SECB) /* \_SB_.PCI0.RP01.UPSB.DSB1.UPS0.DSB4.UPS0.DSB0.SECB */
                                    }

                                    Method (_STA, 0, NotSerialized)  // _STA: Status
                                    {
                                        Return (0x0F)
                                    }

                                    Device (DEV0)
                                    {
                                        Name (_ADR, Zero)  // _ADR: Address
                                        Method (_STA, 0, NotSerialized)  // _STA: Status
                                        {
                                            Return (0x0F)
                                        }

                                        Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                        {
                                            Return (One)
                                        }
                                    }
                                }

                                Device (DSB3)
                                {
                                    Name (_ADR, 0x00030000)  // _ADR: Address
                                    OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                                    Field (A1E0, ByteAcc, NoLock, Preserve)
                                    {
                                        AVND,   32,
                                        BMIE,   3,
                                        Offset (0x18),
                                        PRIB,   8,
                                        SECB,   8,
                                        SUBB,   8,
                                        Offset (0x1E),
                                            ,   13,
                                        MABT,   1
                                    }

                                    Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                                    {
                                        Return (SECB) /* \_SB_.PCI0.RP01.UPSB.DSB1.UPS0.DSB4.UPS0.DSB3.SECB */
                                    }

                                    Method (_STA, 0, NotSerialized)  // _STA: Status
                                    {
                                        Return (0x0F)
                                    }

                                    Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                    {
                                        Return (One)
                                    }

                                    Device (DEV0)
                                    {
                                        Name (_ADR, Zero)  // _ADR: Address
                                        Method (_STA, 0, NotSerialized)  // _STA: Status
                                        {
                                            Return (0x0F)
                                        }

                                        Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                        {
                                            Return (One)
                                        }
                                    }
                                }

                                Device (DSB4)
                                {
                                    Name (_ADR, 0x00040000)  // _ADR: Address
                                    OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                                    Field (A1E0, ByteAcc, NoLock, Preserve)
                                    {
                                        AVND,   32,
                                        BMIE,   3,
                                        Offset (0x18),
                                        PRIB,   8,
                                        SECB,   8,
                                        SUBB,   8,
                                        Offset (0x1E),
                                            ,   13,
                                        MABT,   1
                                    }

                                    Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                                    {
                                        Return (SECB) /* \_SB_.PCI0.RP01.UPSB.DSB1.UPS0.DSB4.UPS0.DSB4.SECB */
                                    }

                                    Method (_STA, 0, NotSerialized)  // _STA: Status
                                    {
                                        Return (0x0F)
                                    }

                                    Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                    {
                                        Return (One)
                                    }

                                    Device (DEV0)
                                    {
                                        Name (_ADR, Zero)  // _ADR: Address
                                        Method (_STA, 0, NotSerialized)  // _STA: Status
                                        {
                                            Return (0x0F)
                                        }

                                        Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                        {
                                            Return (One)
                                        }
                                    }
                                }

                                Device (DSB5)
                                {
                                    Name (_ADR, 0x00050000)  // _ADR: Address
                                    OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                                    Field (A1E0, ByteAcc, NoLock, Preserve)
                                    {
                                        AVND,   32,
                                        BMIE,   3,
                                        Offset (0x18),
                                        PRIB,   8,
                                        SECB,   8,
                                        SUBB,   8,
                                        Offset (0x1E),
                                            ,   13,
                                        MABT,   1
                                    }

                                    Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                                    {
                                        Return (SECB) /* \_SB_.PCI0.RP01.UPSB.DSB1.UPS0.DSB4.UPS0.DSB5.SECB */
                                    }

                                    Method (_STA, 0, NotSerialized)  // _STA: Status
                                    {
                                        Return (0x0F)
                                    }

                                    Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                    {
                                        Return (One)
                                    }
                                }

                                Device (DSB6)
                                {
                                    Name (_ADR, 0x00060000)  // _ADR: Address
                                    OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                                    Field (A1E0, ByteAcc, NoLock, Preserve)
                                    {
                                        AVND,   32,
                                        BMIE,   3,
                                        Offset (0x18),
                                        PRIB,   8,
                                        SECB,   8,
                                        SUBB,   8,
                                        Offset (0x1E),
                                            ,   13,
                                        MABT,   1
                                    }

                                    Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                                    {
                                        Return (SECB) /* \_SB_.PCI0.RP01.UPSB.DSB1.UPS0.DSB4.UPS0.DSB6.SECB */
                                    }

                                    Method (_STA, 0, NotSerialized)  // _STA: Status
                                    {
                                        Return (0x0F)
                                    }

                                    Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                    {
                                        Return (One)
                                    }
                                }
                            }
                        }

                        Device (DSB5)
                        {
                            Name (_ADR, 0x00050000)  // _ADR: Address
                            OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                            Field (A1E0, ByteAcc, NoLock, Preserve)
                            {
                                AVND,   32,
                                BMIE,   3,
                                Offset (0x18),
                                PRIB,   8,
                                SECB,   8,
                                SUBB,   8,
                                Offset (0x1E),
                                    ,   13,
                                MABT,   1
                            }

                            Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                            {
                                Return (SECB) /* \_SB_.PCI0.RP01.UPSB.DSB1.UPS0.DSB5.SECB */
                            }

                            Method (_STA, 0, NotSerialized)  // _STA: Status
                            {
                                Return (0x0F)
                            }

                            Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                            {
                                Return (One)
                            }
                        }

                        Device (DSB6)
                        {
                            Name (_ADR, 0x00060000)  // _ADR: Address
                            OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                            Field (A1E0, ByteAcc, NoLock, Preserve)
                            {
                                AVND,   32,
                                BMIE,   3,
                                Offset (0x18),
                                PRIB,   8,
                                SECB,   8,
                                SUBB,   8,
                                Offset (0x1E),
                                    ,   13,
                                MABT,   1
                            }

                            Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                            {
                                Return (SECB) /* \_SB_.PCI0.RP01.UPSB.DSB1.UPS0.DSB6.SECB */
                            }

                            Method (_STA, 0, NotSerialized)  // _STA: Status
                            {
                                Return (0x0F)
                            }

                            Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                            {
                                Return (One)
                            }
                        }
                    }
                }

                Device (DSB2)
                {
                    Name (_ADR, 0x00040000)  // _ADR: Address
                    Name (_SUN, 0x03)  // _SUN: Slot User Number
                    OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                    Field (A1E0, ByteAcc, NoLock, Preserve)
                    {
                        AVND,	32,
                        BMIE,	3,
                        Offset (0x18),
                        PRIB,	8,
                        SECB,	8,
                        SUBB,	8,
                        Offset (0x1E),
                            ,	13,
                        MABT,	1
                    }

                    Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                    {
                        Return (SECB)
                    }

                    Method (_STA, 0, NotSerialized)  // _STA: Status
                    {
                        Return (0x0F)
                    }

                    Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                    {
                        Return (Zero)
                    }

                    Device (UPS0)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        OperationRegion (ARE0, PCI_Config, Zero, 0x04)
                        Field (ARE0, ByteAcc, NoLock, Preserve)
                        {
                            AVND,	16
                        }

                        Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                        {
                            Return (One)
                        }

                        Device (DSB0)
                        {
                            Name (_ADR, Zero)  // _ADR: Address
                            OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                            Field (A1E0, ByteAcc, NoLock, Preserve)
                            {
                                AVND,	32,
                                BMIE,	3,
                                Offset (0x18),
                                PRIB,	8,
                                SECB,	8,
                                SUBB,	8,
                                Offset (0x1E),
                                    ,	13,
                                MABT,	1,
                                Offset (0x3E),
                                    ,	6,
                                SBRS,	1
                            }

                            Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                            {
                                Return (SECB)
                            }

                            Method (_STA, 0, NotSerialized)  // _STA: Status
                            {
                                Return (0x0F)
                            }

                            Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                            {
                                Return (One)
                            }

                            Device (DEV0)
                            {
                                Name (_ADR, Zero)  // _ADR: Address
                                Method (_STA, 0, NotSerialized)  // _STA: Status
                                {
                                    Return (0x0F)
                                }

                                Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                {
                                    Return (One)
                                }
                            }
                        }

                        Device (DSB3)
                        {
                            Name (_ADR, 0x00030000)  // _ADR: Address
                            OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                            Field (A1E0, ByteAcc, NoLock, Preserve)
                            {
                                AVND,	32,
                                BMIE,	3,
                                Offset (0x18),
                                PRIB,	8,
                                SECB,	8,
                                SUBB,	8,
                                Offset (0x1E),
                                    ,	13,
                                MABT,	1
                            }

                            Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                            {
                                Return (SECB)
                            }

                            Method (_STA, 0, NotSerialized)  // _STA: Status
                            {
                                Return (0x0F)
                            }

                            Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                            {
                                Return (One)
                            }

                            Device (UPS0)
                            {
                                Name (_ADR, Zero)  // _ADR: Address
                                OperationRegion (ARE0, PCI_Config, Zero, 0x04)
                                Field (ARE0, ByteAcc, NoLock, Preserve)
                                {
                                    AVND,	16
                                }

                                Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                {
                                    Return (One)
                                }

                                Device (DSB0)
                                {
                                    Name (_ADR, Zero)  // _ADR: Address
                                    OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                                    Field (A1E0, ByteAcc, NoLock, Preserve)
                                    {
                                        AVND,	32,
                                        BMIE,	3,
                                        Offset (0x18),
                                        PRIB,	8,
                                        SECB,	8,
                                        SUBB,	8,
                                        Offset (0x1E),
                                            ,	13,
                                        MABT,	1,
                                        Offset (0x3E),
                                            ,	6,
                                        SBRS,	1
                                    }

                                    Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                                    {
                                        Return (SECB)
                                    }

                                    Method (_STA, 0, NotSerialized)  // _STA: Status
                                    {
                                        Return (0x0F)
                                    }

                                    Device (DEV0)
                                    {
                                        Name (_ADR, Zero)  // _ADR: Address
                                        Method (_STA, 0, NotSerialized)  // _STA: Status
                                        {
                                            Return (0x0F)
                                        }
                                    }
                                }

                                Device (DSB3)
                                {
                                    Name (_ADR, 0x00030000)  // _ADR: Address
                                    OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                                    Field (A1E0, ByteAcc, NoLock, Preserve)
                                    {
                                        AVND,	32,
                                        BMIE,	3,
                                        Offset (0x18),
                                        PRIB,	8,
                                        SECB,	8,
                                        SUBB,	8,
                                        Offset (0x1E),
                                            ,	13,
                                        MABT,	1
                                    }

                                    Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                                    {
                                        Return (SECB)
                                    }

                                    Method (_STA, 0, NotSerialized)  // _STA: Status
                                    {
                                        Return (0x0F)
                                    }

                                    Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                    {
                                        Return (One)
                                    }

                                    Device (DEV0)
                                    {
                                        Name (_ADR, Zero)  // _ADR: Address
                                        Method (_STA, 0, NotSerialized)  // _STA: Status
                                        {
                                            Return (0x0F)
                                        }

                                        Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                        {
                                            Return (One)
                                        }
                                    }
                                }

                                Device (DSB4)
                                {
                                    Name (_ADR, 0x00040000)  // _ADR: Address
                                    OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                                    Field (A1E0, ByteAcc, NoLock, Preserve)
                                    {
                                        AVND,	32,
                                        BMIE,	3,
                                        Offset (0x18),
                                        PRIB,	8,
                                        SECB,	8,
                                        SUBB,	8,
                                        Offset (0x1E),
                                            ,	13,
                                        MABT,	1
                                    }

                                    Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                                    {
                                        Return (SECB)
                                    }

                                    Method (_STA, 0, NotSerialized)  // _STA: Status
                                    {
                                        Return (0x0F)
                                    }

                                    Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                    {
                                        Return (One)
                                    }

                                    Device (DEV0)
                                    {
                                        Name (_ADR, Zero)  // _ADR: Address
                                        Method (_STA, 0, NotSerialized)  // _STA: Status
                                        {
                                            Return (0x0F)
                                        }

                                        Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                        {
                                            Return (One)
                                        }
                                    }
                                }

                                Device (DSB5)
                                {
                                    Name (_ADR, 0x00050000)  // _ADR: Address
                                    OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                                    Field (A1E0, ByteAcc, NoLock, Preserve)
                                    {
                                        AVND,	32,
                                        BMIE,	3,
                                        Offset (0x18),
                                        PRIB,	8,
                                        SECB,	8,
                                        SUBB,	8,
                                        Offset (0x1E),
                                            ,	13,
                                        MABT,	1
                                    }

                                    Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                                    {
                                        Return (SECB)
                                    }

                                    Method (_STA, 0, NotSerialized)  // _STA: Status
                                    {
                                        Return (0x0F)
                                    }

                                    Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                    {
                                        Return (One)
                                    }
                                }

                                Device (DSB6)
                                {
                                    Name (_ADR, 0x00060000)  // _ADR: Address
                                    OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                                    Field (A1E0, ByteAcc, NoLock, Preserve)
                                    {
                                        AVND,	32,
                                        BMIE,	3,
                                        Offset (0x18),
                                        PRIB,	8,
                                        SECB,	8,
                                        SUBB,	8,
                                        Offset (0x1E),
                                            ,	13,
                                        MABT,	1
                                    }

                                    Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                                    {
                                        Return (SECB)
                                    }

                                    Method (_STA, 0, NotSerialized)  // _STA: Status
                                    {
                                        Return (0x0F)
                                    }

                                    Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                    {
                                        Return (One)
                                    }
                                }
                            }
                        }

                        Device (DSB4)
                        {
                            Name (_ADR, 0x00040000)  // _ADR: Address
                            OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                            Field (A1E0, ByteAcc, NoLock, Preserve)
                            {
                                AVND,	32,
                                BMIE,	3,
                                Offset (0x18),
                                PRIB,	8,
                                SECB,	8,
                                SUBB,	8,
                                Offset (0x1E),
                                    ,	13,
                                MABT,	1
                            }

                            Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                            {
                                Return (SECB)
                            }

                            Method (_STA, 0, NotSerialized)  // _STA: Status
                            {
                                Return (0x0F)
                            }

                            Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                            {
                                Return (One)
                            }

                            Device (UPS0)
                            {
                                Name (_ADR, Zero)  // _ADR: Address
                                OperationRegion (ARE0, PCI_Config, Zero, 0x04)
                                Field (ARE0, ByteAcc, NoLock, Preserve)
                                {
                                    AVND,	16
                                }

                                Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                {
                                    Return (One)
                                }

                                Device (DSB0)
                                {
                                    Name (_ADR, Zero)  // _ADR: Address
                                    OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                                    Field (A1E0, ByteAcc, NoLock, Preserve)
                                    {
                                        AVND,	32,
                                        BMIE,	3,
                                        Offset (0x18),
                                        PRIB,	8,
                                        SECB,	8,
                                        SUBB,	8,
                                        Offset (0x1E),
                                            ,	13,
                                        MABT,	1,
                                        Offset (0x3E),
                                            ,	6,
                                        SBRS,	1
                                    }

                                    Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                                    {
                                        Return (SECB)
                                    }

                                    Method (_STA, 0, NotSerialized)  // _STA: Status
                                    {
                                        Return (0x0F)
                                    }

                                    Device (DEV0)
                                    {
                                        Name (_ADR, Zero)  // _ADR: Address
                                        Method (_STA, 0, NotSerialized)  // _STA: Status
                                        {
                                            Return (0x0F)
                                        }

                                        Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                        {
                                            Return (One)
                                        }
                                    }
                                }

                                Device (DSB3)
                                {
                                    Name (_ADR, 0x00030000)  // _ADR: Address
                                    OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                                    Field (A1E0, ByteAcc, NoLock, Preserve)
                                    {
                                        AVND,	32,
                                        BMIE,	3,
                                        Offset (0x18),
                                        PRIB,	8,
                                        SECB,	8,
                                        SUBB,	8,
                                        Offset (0x1E),
                                            ,	13,
                                        MABT,	1
                                    }

                                    Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                                    {
                                        Return (SECB)
                                    }

                                    Method (_STA, 0, NotSerialized)  // _STA: Status
                                    {
                                        Return (0x0F)
                                    }

                                    Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                    {
                                        Return (One)
                                    }

                                    Device (DEV0)
                                    {
                                        Name (_ADR, Zero)  // _ADR: Address
                                        Method (_STA, 0, NotSerialized)  // _STA: Status
                                        {
                                            Return (0x0F)
                                        }

                                        Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                        {
                                            Return (One)
                                        }
                                    }
                                }

                                Device (DSB4)
                                {
                                    Name (_ADR, 0x00040000)  // _ADR: Address
                                    OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                                    Field (A1E0, ByteAcc, NoLock, Preserve)
                                    {
                                        AVND,	32,
                                        BMIE,	3,
                                        Offset (0x18),
                                        PRIB,	8,
                                        SECB,	8,
                                        SUBB,	8,
                                        Offset (0x1E),
                                            ,	13,
                                        MABT,	1
                                    }

                                    Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                                    {
                                        Return (SECB)
                                    }

                                    Method (_STA, 0, NotSerialized)  // _STA: Status
                                    {
                                        Return (0x0F)
                                    }

                                    Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                    {
                                        Return (One)
                                    }

                                    Device (DEV0)
                                    {
                                        Name (_ADR, Zero)  // _ADR: Address
                                        Method (_STA, 0, NotSerialized)  // _STA: Status
                                        {
                                            Return (0x0F)
                                        }

                                        Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                        {
                                            Return (One)
                                        }
                                    }
                                }

                                Device (DSB5)
                                {
                                    Name (_ADR, 0x00050000)  // _ADR: Address
                                    OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                                    Field (A1E0, ByteAcc, NoLock, Preserve)
                                    {
                                        AVND,	32,
                                        BMIE,	3,
                                        Offset (0x18),
                                        PRIB,	8,
                                        SECB,	8,
                                        SUBB,	8,
                                        Offset (0x1E),
                                            ,	13,
                                        MABT,	1
                                    }

                                    Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                                    {
                                        Return (SECB)
                                    }

                                    Method (_STA, 0, NotSerialized)  // _STA: Status
                                    {
                                        Return (0x0F)
                                    }

                                    Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                    {
                                        Return (One)
                                    }
                                }

                                Device (DSB6)
                                {
                                    Name (_ADR, 0x00060000)  // _ADR: Address
                                    OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                                    Field (A1E0, ByteAcc, NoLock, Preserve)
                                    {
                                        AVND,	32,
                                        BMIE,	3,
                                        Offset (0x18),
                                        PRIB,	8,
                                        SECB,	8,
                                        SUBB,	8,
                                        Offset (0x1E),
                                            ,	13,
                                        MABT,	1
                                    }

                                    Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                                    {
                                        Return (SECB)
                                    }

                                    Method (_STA, 0, NotSerialized)  // _STA: Status
                                    {
                                        Return (0x0F)
                                    }

                                    Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                                    {
                                        Return (One)
                                    }
                                }
                            }
                        }

                        Device (DSB5)
                        {
                            Name (_ADR, 0x00050000)  // _ADR: Address
                            OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                            Field (A1E0, ByteAcc, NoLock, Preserve)
                            {
                                AVND,	32,
                                BMIE,	3,
                                Offset (0x18),
                                PRIB,	8,
                                SECB,	8,
                                SUBB,	8,
                                Offset (0x1E),
                                    ,	13,
                                MABT,	1
                            }

                            Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                            {
                                Return (SECB)
                            }

                            Method (_STA, 0, NotSerialized)  // _STA: Status
                            {
                                Return (0x0F)
                            }

                            Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                            {
                                Return (One)
                            }
                        }

                        Device (DSB6)
                        {
                            Name (_ADR, 0x00060000)  // _ADR: Address
                            OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                            Field (A1E0, ByteAcc, NoLock, Preserve)
                            {
                                AVND,	32,
                                BMIE,	3,
                                Offset (0x18),
                                PRIB,	8,
                                SECB,	8,
                                SUBB,	8,
                                Offset (0x1E),
                                    ,	13,
                                MABT,	1
                            }

                            Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                            {
                                Return (SECB) /* \_SB_.PCI0.RP01.UPSB.DSB2.UPS0.DSB6.SECB */
                            }

                            Method (_STA, 0, NotSerialized)  // _STA: Status
                            {
                                Return (0x0F)
                            }

                            Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                            {
                                Return (One)
                            }
                        }
                    }
                }

                Device (DSB3)
                {
                    Name (_ADR, 0x00050000)  // _ADR: Address
                    Name (_SUN, 0x04)  // _SUN: Slot User Number
                    Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                    {
                        Return (Zero)
                    }

                    OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                    Field (A1E0, ByteAcc, NoLock, Preserve)
                    {
                        AVND,	32,
                        BMIE,	3,
                        Offset (0x18),
                        PRIB,	8,
                        SECB,	8,
                        SUBB,	8,
                        Offset (0x1E),
                            ,	13,
                        MABT,	1
                    }

                    Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                    {
                        Return (SECB) /* \_SB_.PCI0.RP01.UPSB.DSB3.SECB */
                    }

                    Method (_STA, 0, NotSerialized)  // _STA: Status
                    {
                        Return (0x0F)
                    }
                }

                Device (DSB4)
                {
                    Name (_ADR, 0x00060000)  // _ADR: Address
                    Name (_SUN, 0x05)  // _SUN: Slot User Number
                    OperationRegion (A1E0, PCI_Config, Zero, 0x40)
                    Field (A1E0, ByteAcc, NoLock, Preserve)
                    {
                        AVND,   32,
                        BMIE,   3,
                        Offset (0x18),
                        PRIB,   8,
                        SECB,   8,
                        SUBB,   8,
                        Offset (0x1E),
                            ,   13,
                        MABT,   1
                    }

                    Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
                    {
                        Return (SECB) /* \_SB_.PCI0.RP01.UPSB.DSB4.SECB */
                    }

                    Method (_STA, 0, NotSerialized)  // _STA: Status
                    {
                        Return (0x0F)
                    }

                    Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                    {
                        Return (Zero)
                    }
                }

                Method (_DSM, 4, NotSerialized)  // _DSM: Device-Specific Method
                {
                    If (!Arg2)
                    {
                        Return (Buffer (One)
                        {
                            0x03
                        })
                    }

                    Return (Package (0x02)
                    {
                        "PCI-Thunderbolt",
                        One
                    })
                }
            }
        }
    }
}
