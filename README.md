# Draconic Reactor Control Script

This project contains a Lua script for controlling a Draconic Reactor in the Draconic Evolution mod, version 1.12.2. The script is designed to run on a computer within the Minecraft mod and provides a user interface and automated control for the reactor.

## Features

- Real-time monitoring of reactor status, temperature, field strength, and other critical metrics.
- Interactive control panel for setting target field strength, saturation, and power increments.
- Automated adjustments to the reactor's flux gates based on the current status and target parameters.
- Emergency shutdown feature for overheating or other critical scenarios.

## Requirements

- Minecraft with Draconic Evolution mod version 1.12.2.
- ComputerCraft or similar mod providing in-game computers and peripherals.

## Installation

1. Place the script in your Minecraft mod's scripts directory.
2. Modify the peripheral configuration section in the script to match your setup:
   - `monitorName` should be the side of the computer where the monitor is attached.
   - `reactorName` should be the name of your Draconic Reactor.
   - `fluxgateInName` and `fluxgateOutName` should be the names of your input and output flux gates.

## Usage

1. Run the script on an in-game computer.
2. Interact with the displayed interface on the monitor to control the reactor:
   - Use the touchscreen functionality to adjust target values and control reactor operations.
   - Monitor reactor status, field strength, saturation, temperature, and power output in real-time.

## Disclaimer

This script is provided "as is", without warranty of any kind. Use at your own risk. The author is not responsible for any damage or loss caused by using this script.

## Contributing

Contributions to this project are welcome. Please feel free to fork the repository, make your changes, and submit a pull request.

---

*This README was generated using AI assistance.*
