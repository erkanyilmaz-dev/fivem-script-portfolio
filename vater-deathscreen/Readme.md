# 💀 vater-deathscreen | Advanced Combat Deathscreen & Elimination Analytics

> **vater-deathscreen** is an ultra-fast, visually captivating death and respawn management system tailored for FiveM servers. Designed for both roleplay and high-tempo competitive PvP environments, it instantly reveals detailed elimination telematics when a player falls—including the killer's identity, server ID, distance, weapon used, and dynamic respawn/bleedout timers.

---

## 🚀 Key Features

* **🎯 Elimination Telematics:** Displays the killer's character name, server ID (`Server ID: #12`), distance of the fatal shot, weapon icon, and body hit location.
* **⏱️ Dynamic Bleedout & Respawn Timers:** Clean progress indicators for bleedout countdowns, medical call requests, and instant respawn options.
* **🚑 Interactive EMS Signal & Dispatch:** Send dynamic distress signals directly to active emergency services with exact GPS coordinates.
* **🎥 Cinematic Death Cam & FX:** Smooth camera focus options, customizable visual filters (grayscale, blur, vignette), and immersive audio transitions upon incapacitation.
* **⚡ Ultra-Optimized Performance:** Operates at `0.00ms` on idle, utilizing asynchronous NUI events to ensure smooth frame rates during heavy firefights.
* **🛡️ Combat Logging Safeguard:** Built-in quit prevention and state restoration to ensure fair gameplay during active combat situations.

---

## 📦 Dependencies

Ensure the following resources are installed on your server prior to running this script:

* **Framework:** `qb-core`, `es_extended` (ESX), or Standalone
* **Medical Systems (Optional):** `qb-ambulancejob`, `esx_ambulancejob`, or custom medical scripts
* **UI / Utility:** `ox_lib`

---

## ⚙️ Installation

1. Download or clone the repository into your server's resources directory:
   ```bash
   git clone [https://github.com/YOUR_USERNAME/vater-deathscreen.git](https://github.com/YOUR_USERNAME/vater-deathscreen.git)
