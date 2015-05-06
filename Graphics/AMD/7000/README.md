# AMD 7000 Series Patches

DSDT patches for AMD Radeon HD 7000 series GPUs on OS X.

## Customizing These Patches For Your Card
The 7970 patch in this repo is specifically for the Sapphire Radeon HD 7970 Dual-X OC with Boost using the Hamachi framebuffer. If you want to make some minor cosmetic adjustments, you can change the ROM number (this can usually be found in the VBIOS of your card).

## Editing Framebuffer Personalities
The Sapphire Radeon HD 7970 Dual-X OC with Boost has 2x DVI, 1x HDMI, and 1x DP. None of the stock 7000 personalities work with this card, so we need to patch the framebuffer (in this case, `Hamachi`). This guide will be based off the process for this card, it may differ slightly for other cards.

Using [`radeon_bios_decode`](http://www.insanelymac.com/forum/files/file/190-redsock-bios-decoder-and-radeon-bios-decode/) and [`redsock_bios_decoder`](http://www.insanelymac.com/forum/files/file/190-redsock-bios-decoder-and-radeon-bios-decode/) with the VBIOS of the card (can be extracted using GPU-Z)
[rest of guide in progress]

#### 

#### Applying the patched framebuffer to the kext
After modifying the framebuffer, we must patch the AMD7000Controller kext and replace the Hamachi framebuffer with our modified one. This can be done in multiple ways.

- Clover auto-patching (recommended, applied at every boot)

  Insert this in your config.plist, under KextsToPatch.
  
  ```plist
  <dict>
    <key>Comment</key>
    <string>10.9-10.10-AMD7000Controller/Hamachi Framebuffer Patch</string>
    <key>Find</key>
    <data>AAQAAAQDAAAAAQEBEgQFAQAEAAAEAwAAAAECASIFBAIEAAAAFAIAAAABAwAAAAMGAAgAAAQCAAAAAQQAEQIBBA==</data>
    <key>Name</key>
    <string>AMD7000Controller</string>
    <key>Replace</key>
    <data>AAQAAAQDAAAAAQAAEgQBAQAIAAAEAgAAAAEAACIFAgQAAgAABAIAAAABAAARAgMDBAAAABQCAAAAAQAAEAAEBg==</data>
  </dict>
  ```
  The `<data>` under `Find` (the original framebuffer) and `Replace` (the patched framebuffer) is encoded as base64. Use a PLIST editor such as Xcode to insert the framebuffer.

- Manually patching the kext (needs to be applied after every OS update)

  Replace the stock framebuffer with our patched one:

  `sudo perl -pi -e 's|\x00\x04\x00\x00\x04\x03\x00\x00\x00\x01\x01\x01\x12\x04\x05\x01\x00\x04\x00\x00\x04\x03\x00\x00\x00\x01\x02\x01\x22\x05\x04\x02\x04\x00\x00\x00\x14\x02\x00\x00\x00\x01\x03\x00\x00\x00\x03\x06\x00\x08\x00\x00\x04\x02\x00\x00\x00\x01\x04\x00\x11\x02\x01\x04|\x00\x04\x00\x00\x04\x03\x00\x00\x00\x01\x00\x00\x12\x04\x01\x01\x00\x08\x00\x00\x04\x02\x00\x00\x00\x01\x00\x00\x22\x05\x02\x04\x00\x02\x00\x00\x04\x02\x00\x00\x00\x01\x00\x00\x11\x02\x03\x03\x04\x00\x00\x00\x14\x02\x00\x00\x00\x01\x00\x00\x10\x00\x04\x06|g' /System/Library/Extensions/AMD7000Controller.kext/Contents/MacOS/AMD7000Controller`
  
  Rebuild kext caches:
  
  `sudo touch /System/Library/Extensions`
  
  `sudo kextcache -system-caches`
  
  `sudo kextcache -system-prelinked-kernel`
