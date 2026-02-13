# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Linux controller for the Thermalright USB LCD screen. It displays system metrics (CPU/GPU temperature and usage) on a USB HID device with 84 individually addressable LEDs arranged as 7-segment displays.

The project communicates with a USB HID device (Vendor ID: 0x0416, Product ID: 0x8001) and sends color data packets to control the LED display.

## Development Commands

### Setup
```bash
# Create virtual environment and install dependencies
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Running the Application
```bash
# Run controller with default config
python src/controller.py

# Run controller with custom config path
python src/controller.py /path/to/config.json

# Run the GUI for live preview and color customization
python src/led_display_ui.py

# Run the shell script menu for configuration
./led_control.sh
```

### Installation/Uninstallation
```bash
# Install systemd service and udev rules (requires root)
sudo ./install.sh

# Uninstall service and udev rules (requires root)
sudo ./uninstall.sh
```

## Architecture

### Core Components

1. **controller.py** - Main display controller
   - `Controller` class: Manages HID device communication and display rendering
   - Loads config from `config.json` (or path from `DIGITAL_LCD_CONFIG` env var)
   - Main loop runs in `display()` method, refreshing at configured `update_interval`
   - Sends LED data via HID packets (1 header packet + 4 data packets per frame)

2. **metrics.py** - System metrics collection
   - `Metrics` class: Auto-detects and caches best metric collection method for the system
   - Supports multiple backends: psutil, Linux sysfs, Windows WMI, nvidia-smi, AMD pyamdgpuinfo
   - Caches metrics based on `metrics_update_interval` to avoid excessive polling

3. **config.py** - Configuration constants
   - LED index mappings for both "big" (84 LEDs) and "small" (31 LEDs) layout modes
   - Default configuration structure
   - Display mode lists for each layout

4. **utils.py** - Utility functions
   - `interpolate_color()`: Linear color interpolation for gradients
   - `get_random_color()`: Random color generation

5. **led_display_ui.py** - GUI application (Tkinter-based)
   - Live preview of LED configuration
   - Color customization interface

### Configuration System

The `config.json` file controls all display behavior:

- **display_mode**: Determines what content is shown (metrics, time, peerless_standard, etc.)
- **layout_mode**: "big" (84 LEDs) or "small" (31 LEDs)
- **metrics.colors** / **time.colors**: Array of 84 color values, one per LED
- **gpu_vendor**: "nvidia" or "amd" - affects which metric collection methods are used
- Temperature units, min/max thresholds, update intervals

### Color System

Colors in config.json support multiple formats:
- Static hex: `"ff0000"` (red)
- Random: `"random"`
- 2-color gradient with metric: `"0000ff-ff0000-cpu_temp"` (blue to red based on CPU temp)
- Multi-stop gradient: `"cpu_temp;0000ff:30;00ff00:50;ff0000:80"` (blue at 30°C, green at 50°C, red at 80°C)
- Time-based gradient: `"00d9d9-ffd900-seconds"` (cycles based on seconds)
- Rainbow animation: `"ff0000-00ff00-0000ff"` (cycles through colors over time)
- Wave animations: `"wave_ltr;ff0000-00ff00-0000ff"` or `"wave_rtl;..."`

All gradient interpolation happens in `Controller.get_config_colors()` at controller.py:321.

### LED Layout System

Two layout files define LED positioning:
- **layout.json**: Maps logical display regions to LED indices (used by peerless display modes)
- **peerless_layout.json**: Alternative layout mapping

The `leds_indexes` dict in config.py provides named LED groups for the "big" layout.

### Display Modes

Each mode has a corresponding method in Controller class:
- **metrics**: CPU+GPU temp/usage on both sides
- **peerless_standard**: Dual metrics using layout.json mapping
- **peerless_temp**: Temperature only display
- **peerless_usage**: Usage only display
- **time modes**: Various clock displays
- **alternate_***: Modes that cycle between different displays

Small layout modes are limited (see `display_modes_small` in config.py).

### HID Communication

- Device communication uses the `hid` library (hidapi)
- Data is sent as 5 packets per frame: 1 header (128 bytes) + 4 continuation (128 bytes each)
- Header format: `'dadbdcdd000000000000000000000000fc0000ff' + color_data`
- Each LED contributes 6 hex characters (RGB) to the message
- See `Controller.send_packets()` at controller.py:118

## Important Notes

- The controller runs in an infinite loop (`Controller.display()`) - it's designed to run as a systemd service
- Metrics collection auto-selects the best method on init - if adding new metric sources, follow the pattern in `Metrics.__init__()`
- When adding new display modes, update the appropriate `display_modes` or `display_modes_small` list in config.py
- The config file is reloaded on every display loop iteration, allowing live configuration changes
- Temperature unit conversion (C/F) happens in `Metrics.get_metrics()`, not in the controller
