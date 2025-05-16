# macOS VirtualBox VM

This manual allows to setup macOS VirtualBox Virtual Machine, along with a commands for preparing a bootable install ISO image from a downloaded Mac OS installer app.

*Note: The `hdutil` commands is tailored to run on a macOS hosts, and the macOS installer app on it. 

## Prerequisites

- You need a Virtualbox installed on your hypervisor host (Win/Linux/Mac/whatever) and at least 60GB of a free disk space for ISO (macOS installer) and VDI (virtual disk of the VM)
- At least 70 GB of the free space **on the source macOS device** for generation of the ISO file with macOS installer (but in fact, it is the macOS recovery disk).
- Download the macOS installer app if you have not already - search it as "Install macOS" in your [AppStore](https://apps.apple.com/ru/story/id1784326336?l=en-US). It should be located in your `Applications` directory.

## Part 1: Generate ISO on the Mac

- Prepare your virtual image with
  ```
  hdiutil create -o /tmp/Sequoia -size 17g -volname ISO -layout SPUD -fs HFS+J -type UDTO -attach
  ```
- Follow this command according to your distro to fill the image: https://support.apple.com/en-us/101578 As an example, for Sequoia, it should be:
  ```
  sudo /Applications/Install\ macOS\ Sequoia.app/Contents/Resources/createinstallmedia --volume /Volumes/ISO
  ```
- Then, eject/unmount the ISO volume from your left panel in the Finder
- Convert it:
  ```
  hdiutil convert /tmp/Sequoia.cdr -format UDTO -o Sequoia.iso
  ```
- Copy the resulting `Sequoia.iso` file from your desktop to your hypervisor host

## Part 2: Initial configuration of the VM on the hypervisor host

In the VirtualBox GUI: 
- Create OS X VM.
- Call it "Sequoia", for example. It will be used in commands below.
- Select at least 40GB size disk.
- Allocate not less 8GB of RAM
- Check whether it uses EFI boot mode. Show it boot disk to the generated ISO file.
- Use SATA AHCI controller for HDD. Avoid an SSD emulation.

OR:
- Open the virtual machine file config from the repo (`.vbox` file) and copy the ExtraData into `%USERPROFILE%\.VirtualBox\...\Sequoia\Sequoia.vbox`
- Create a new virtual hard disk. Make sure that your new virtual hard drive is not set as an SSD, otherwise the macOS installer will format the drive as APFS, which is not yet recognized/supported by VirtualBox's EFI BIOS and you will not be able to boot from the hard drive.
- Set the `Sequoia.iso` as an inserted disk in the VM's optical drive 
  
## Part 3: Patch the configuration of the VM you have created.

- Allow it to have TPM 2.0 module with ICH9 mainboard.
- On the Microsoft Windows:
  - press Win+R, run console by entering `cmd` and pressing Enter after it;
  - point it to a folder with your VirtualBox installed with the next command in the console:
    ```
    cd /d "%VBOX_MSI_INSTALL_PATH%"
    ```
    to make the commands below executable.
- Use VMSVGA without acceleration and 256MB of memory:
  ```
  VBoxManage modifyvm "Sequoia" --vram 256
  ```
- Set the desired screen resolution (I've set 1600x900):
  ```
  VBoxManage setextradata "Sequoia" VBoxInternal2/EfiGraphicsResolution 1600x900
  ```
- Tune the CPU:
  ```
  VBoxManage modifyvm "Sequoia" --cpuidset 00000001 000106e5 00100800 0098e3fd bfebfbff
  ```
- Add special extra data into the configuration:
  ```
  VBoxManage setextradata "Sequoia" "VBoxInternal/Devices/efi/0/Config/DmiSystemProduct" "iMac11,3"
  VBoxManage setextradata "Sequoia" "VBoxInternal/Devices/efi/0/Config/DmiSystemVersion" "1.0"
  VBoxManage setextradata "Sequoia" "VBoxInternal/Devices/efi/0/Config/DmiBoardProduct" "Iloveapple"
  VBoxManage setextradata "Sequoia" "VBoxInternal/Devices/smc/0/Config/DeviceKey" "ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"
  VBoxManage setextradata "Sequoia" "VBoxInternal/Devices/smc/0/Config/GetKeyFromRealSMC" 0
  ```

## Part 4: installation

- Detach or disable a networking device for VM.
- Start the VM, and wait for the macOS installer boot.
- When the boot completed, open **Disk Utility**. From the **View** menu enable the option to "Show all devices", and erase the virtual hard disk you have attached to this VM before and select Mac filesystem with journaling.
- Quit the **Disk Utility**, and install MacOS to the newly initialized hard drive.
- When the installer completes, reboot the VM. 
- Remove the ISO disk from the virtual optical drive and reboot the VM again.
- With the Installer ISO image not available to boot from, you will be dumped into the EFI Shell. Enter the following at the EFI prompt to boot macOS from the virtual hard drive and finish installation:
  ```
  FS1:"macOS Install Data\Locked Files\Boot Files\boot.efi"
  ```
  Alternatively, you can enter `exit` at the prompt to go to the EFI BIOS boot screen, and use the `Boot from file` option to navigate to boot.efi. This is required only once.

## Post installation steps

If you don't need to bind with your Apple ID (for example, if you are preparing the redistributable image), skip this step on the welcome step. The skip option will be on the top of the form which asks your e-mail/Apple ID.

## Limitations

- No 2D/3D/OpenGL acceleration is supported for macOS, no 3D rendering is working (DRI/OGL view shows as an empty zone on the screen)
- No Virtualbox Guest Tools are available for macOS, no shared folders are available
