# DVDStyler - Modernized Windows Fork

[![License](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](COPYING)
[![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey.svg)]()

This repository is an updated and modernized fork of **DVDStyler**, a cross-platform free DVD authoring application for the creation of professional-looking DVDs.

## Why this Fork?

The official version of DVDStyler can sometimes be difficult to compile or run on modern Windows environments due to aging dependencies. Furthermore, many users experience **significant UI lag and stuttering** when dealing with complex menus or high-resolution assets in the official release.

This fork aims to provide a **"Just Works"** experience—smoother, faster, and easier to build.

### Key Improvements:

- **Modern Build System**: Fully compatible with **MSYS2 UCRT64** (Universal C Runtime).
- **FFmpeg Integration**: Updated for compatibility with modern FFmpeg releases (6.x and higher).
- **Hybrid Dependency Engine**: A robust packaging script that bundles all necessary MSYS2 libraries and legacy authoring tools (`mplex`, `dvdauthor`, etc.) automatically.
- **Enhanced Stability**: Fixed several linker and runtime errors related to modern `wxWidgets` and Windows libraries.
- **Automated Installer**: Integrated support for **Inno Setup** to generate professional `.exe` installers with a single command.

---

## 🚀 Getting Started

### For Users

If you just want to use DVDStyler, download the latest version from the [Releases](https://github.com/your-username/dvdstyler-DVDStyler/releases) section:

- **Installer (.exe)**: Recommended for a standard setup.
- **Portable (.zip)**: Just extract and run `dvdstyler.exe`. No installation required.

### For Developers

To build and package this project yourself:

#### **Windows (MSYS2)**

1.  **Environment**: Install [MSYS2](https://www.msys2.org/) and set up the `ucrt64` environment.
2.  **Dependencies**: Install required packages (wxWidgets, FFmpeg, etc.) via `pacman`.
3.  **Build & Package**: Run our specialized PowerShell script from the root directory:
    ```powershell
    .\package.ps1
    ```

#### **Linux**

This fork remains fully compatible with Linux. Modern distributions with FFmpeg 6+ and wxWidgets 3.2+ will find this code more stable than the original release.

1.  **Dependencies**: Install development headers for `wxWidgets`, `ffmpeg`, `libxml2`, and `dvdauthor` via your package manager (apt, dnf, etc.).
2.  **Build**:
    ```bash
    ./configure
    make
    sudo make install
    ```

---

## 🛠️ Built-in Tools

This fork includes and manages the following essential authoring tools:

- **FFmpeg**: For video transcoding and menu generation.
- **mplex**: For multiplexing audio and video streams.
- **dvdauthor**: For DVD structure and menu authoring.
- **mkisofs**: For ISO image creation.

---

## 📜 License & Credits

- **Original Author**: Alex Thüring (http://www.dvdstyler.org)
- **License**: This project is licensed under the **GNU General Public License v2**.

DVDStyler is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.

---

_Maintainers of this fork are not affiliated with the original DVDStyler team, but we aim to support the community by keeping this great tool functional on modern systems._
