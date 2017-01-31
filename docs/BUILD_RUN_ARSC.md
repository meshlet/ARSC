# Build and Run ARSC

**NOTE:** In case your manage to build and run the ARSC system on a new FPGA board (not listed in [Supported FPGAs](../README.md#supported-fpgas)),
I kindly ask to notify me about it, ideally with short summary of what had to be changed to make the design work on that particular FPGA. Even
better, you may add a new section to this document which is dedicated to that FPGA device.

This document explains how to Build the ARSC design for DE0-CV Altera FPGA board. It also discusses the issue of synthesizing the
design for other FPGAs and describes what might have to be changed in the design to make it work.

## Build for DE0-CV

To Build the ARSC design for any Altera FPGA board, the Quartus Prime environment is required. Download and install the Quartus Prime
environment here: [Quartus Prime Download](https://www.altera.com/products/design-software/fpga-design/quartus-prime/download.html). It is
assumed that FPGA board is connected to your computer and that JTAG driver is installed and is working properly.

### Using Pre-Configured ARSC Quartus Prime Project

The easiest way to Build ARSC for DE0-CV board is to use the provided Quartus Prime project that pre-configured to target the DE0-CV
board. The ARSC Quartus Prime project was created using the Quartus Prime version 16.0. In case you have different version of the Quartus
Prime, you may still be able to use the ARSC project. If you fail to open the ARSC project with your version of Quartus Prime ISE, refer to
[Creating ARSC Quartus Prime Project](#creating-arsc-quartus-prime-project-for-de0-cv-board).

Follow these steps to build and deploy the ARSC design:

1. Open the [arsc_system.qpf](../build/quartus_16/arsc_system/arsc_system.qpf) in Quartus Prime;
2. From the menu **Processing** select **Start Compilation**;
3. After compilation is completed, from menu **Tools** select **Programmer**/
4. If **arsc_system.sof** file is not already select, click **Add File...** button and find and choose the **arsc_system.sof** file;
5. In Programmer window, check if **USB-Blaster** is selected in the **Hardware Setup...** field. If not, click **Hardware Setup...** and select **USB-Blaster**;
6. In the Programmer window, click **Start** to program the FPGA with the ARSC design.

### Creating ARSC Quartus Prime Project for DE0-CV Board

Follow these steps to create a Quartus Prime ARSC project:

1. With Quartus Prime running, from **File** menu select **New**;
2. From the **New** window select **New Quartus Prime Project** and click **OK**;
3. Select the working directory for your project (i.e. path-to-arsc/arsc/build/quartus_xy/arsc_system);
4. For the name of the project use **arsc_system**;
5. For the name of the top level entity use **arsc_system_wrapper**;
6. Click **Next**;
7. Make sure **Empty project** is selected and click **Next**;
8. From the **Add Files** window, click **...** button to add new files;

   Navigate to the ARSC directory and select all of the following files (notation \*.v means all files in that directory with extension .v):
   
   arsc/memory_controller/hdl/\*.v  
   arsc/vga_controller/hdl/\*.v  
   arsc/cpu/hdl/\*.v  
   arsc/arsc_system/hdl/\*.v

9. After selecting all the files click **Next**;
10. Make sure Cyclone V is selected in the **Device Family**;
11. Find and select the device **5CEBA4F23C7** (this is Cyclone V FPGA that comes with the DE0-CV board) and click **Next**;
12. Click **Next**;
13. Click **Finish**.

ARSC system utilizes two on-chip memory modules: onchip_main_ram and video_ram, both of which have their initialization files use to initialize these memories during synthesis and deployment. The two init files in question are:

arsc/build/quartus_16./arsc_system/arsc_main_memory_init.mif  
arsc/build/quartus_16./arsc_system/video_ram_init.mif.

For Quartus Prime to be able to locate these files they should be placed next to the project file itself. Copy these files from the ARSC tree to the location of your Quartus Prime project. The one thing left to do is to import the pin assignments for the DE0-CV board:

1. From **Assignments** menu select **Import Assignments...**;
2. Click the **...** button;
3. Locate and select the arsc/build/quartus_16/de0_cv_default_pins/de0_cv_default_pins.csv.

Now that Quartus Prime project is created and configured, follow the steps in [Using Pre-Configured ARSC Quartus Prime Project](using-pre-configured-arsc-quartus-prime-project) to build and deploy the ARSC design for the DE0-CV board.

## Build ARSC for Other Altera Boards

Make sure to read through all of the following sections and check if your FPGA board satisfies the requirements, and what has to be changed code-wise to make the ARSC design compile for your board. Afterwards, follow the steps described in [Creating ARSC Quartus
Prime Project for DE0-CV Board]( creating-arsc-quartus-prime-project-for-de0-cv-board) to create the Quartus Prime project. Make sure
to select the proper device in step 11. Then, follow
[Using Pre-Configured ARSC Quartus Prime Project](using-pre-configured-arsc-quartus-prime-project) to build the design and program
your FPGA device.

### Reference Clock

It is assumed that your FPGA has a **50MHz** clock source. If this is not the case, an additional PLL will have to be added to derive a 50MHz clock from the board's reference clock.

FIXME: provide more information about overcoming this issue.

### On-Chip Memory

As mentioned earlier, the ARSC design uses two on-chip memory modules: one for main RAM and the other for video RAM. These two module amount to *253952 bytes* of memory (refer to [Programming ARSC](../docs/PROGRAMMING_ARSC.md) for detailed explanation). You'll have
to make sure that your FPGA device has at least as much on-chip memory (for instance, DE0-CV board has *3151920 bits = 393990 bytes*).

Next, it must be possible to configure the on-chip memory as a dual-port memory (that is, it can be accessed by two readers/writters concurrently). In the case of the on-chip main RAM, this is required to enable program loading via the **In-System Memory Content Editor** (check [Program Loading](#program-loading)). Video memory is dual-port to increase the read/write performance, as ARSC CPU
and ARSC video controller can simultaneously read/write the video RAM.

The two on-chip modules instantiated in [onchip_main_ram.v](../memory_controller/hdl/onchip_main_ram.v) and [video_ram.v](../vga_controller/hdl/video_ram.v) should work for most Altera FPGAs (if they have enough on-chip memory that can be configured as
a dual-port). However, it may happen that these on-chip modules may have to be instantiated differently for your FPGA. Note, however,
that these files were not created manually. A Quartus Prime tool called **Qsys** was used for this purpose. Describing **Qsys** is
out of the scope of this document - Altera offers a couple of Qsys tutorials that introduce the user to this tool.

However, you should first try using the provided on-chip memory files and only dig into Qsys in case the Quartus Prime fails to instantiate the on-chip memory module based on these files.

### VGA

ARSC system assumes that the used FPGA board supports the standard VGA resolution (640x480 at 25MHz refresh rate). You have to make sure that your FPGA supports the same VGA resolution. Additionally, while ARSC system supports **3-bit** color depth, the VGA interface on
the DE0-CV board supports **12-bit** color depth. The **3-bit** color depth is decoded to the **12-bit** color depth before the signal
is sent  to the VGA monitor. Thus, if the native color depth of your FPGA is not **12-bit**, some code changes will be required to corrently decode the ARSC **3-bit** color to the target color depth.

#### Color-Depth Relted Code Changes

FIXME: Complete this section

### FPGA Pins

In case your FPGA is not DE0-CV, then FPGA pins will most probably have different names as well. You will have find the default pins .csv file for your board and use it to import pins to your Quartus Prime ARSC project. The good place to look for such a file is in
the supporting System CD of your FPGA board.

Once you obtained or created the default_pins.csv file, you'll also have to make changes in the [arsc_system_wrapper.v](../arsc_system/hdl/arsc_system_wrapper.v) file. This is the top level entity in the ARSC design and its input/output ports must have
names that match with pin names in the default_pins.csv file. Replace the pin names in the original [arsc_system_wrapper.v](../arsc_system/hdl/arsc_system_wrapper.v) file with ones corresponding to your FPGA board.

The SDRAM signals are used only in case external SDRAM is selected for the main RAM memory. This is not yet supported, so you don't have to worry about that part. However, make sure that names of these signals match to the pin names of your FPGA board as well.

## Targeting non-Altera FPGAs

FIXME: add info about what would have to be changed code-wise to make ARSC compile for non-Altera FPGAs (the main change is on-chip instantiation modules)

## Program Loading

It is assumed that you have read the [ARSC Assembler](docs/ARSC_ASSEMBLER.md) document, and you know how to compile the ARSC assembly program to the ARSC executable file.

### Using In-System Memory Content Editor (Altera only)

If you have Altera FPGA device, the easiest way to load the program to the main RAM of the ARSC system is via the In-System Memory Content Editor that comes as part of the Quartus Prime environment. Assuming that you have successfuly compiled the ARSC design for
your Altera FPGA and programmed your device, use the following steps to load a compiled executable file to the ARSC RAM:

1. Compile your ARSC assembly program using the [ARSC Assembler](docs/ARSC_ASSEMBLER.md) - select **MIF** as an output file format;
2. Make sure that your FPGA device is connected to your computer and Quartus Prime is running;
3. From **Tools** menu select **In-System Memory Content Editor**;
4. There should be a single on-chip module instance with instance ID **ARSC**;
5. Right click on the **ARSC** instance and select **Import Data From File**;
6. In the selection windows that pops up, change **Files of type** to **Memory Initialization File (\*.mif)**;
7. Locate your executable .mif file and open it;
8. Right click on the **ARSC** memory instance and select **Write Data to In-System Memory**.

The program has been loaded to the ARSC main memory and it may now be executed by the ARSC CPU.

## Running ARSC

This section assumes that the control signals in the [arsc_system_wrapper.v](../arsc_system/hdl/arsc_system_wrapper.v) top-level module have not been changed. Once the program has been loaded to the ARSC main memory (see [Program Loading](#program-loading)) use the
following steps to run the ARSC machine:

1. Press **KEY 0** on your FPGA board to reset the ARSC system to a known initial state
2. Press **KEY 1** to kick-start the ARSC CPU and other HW components.

While ARSC CPU is active the **LED 0** is turned on. Once the CPU completes the program execution or the ARSC system is reset by pressing the **KEY 0**, the **LED 0** is turned off. Note that pressing **KEY 1** when ARSC system has already been started has no
effect. Start can be called once again only after the system has been reset by pressing the **KEY 0**.
