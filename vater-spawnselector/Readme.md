# 📍 vater-spawnselector | Next-Gen Interactive Spawn Management System

> **vater-spawnselector** is a modern, high-framerate spawn location selection system engineered for FiveM servers. Designed with cinematic camera transitions, dynamic neighborhood previews, live weather/time cards, and job/apartment integrations, it offers players a smooth, high-end arrival experience every time they enter the server.

---

## 🚀 Key Features

* **🎥 Cinematic Camera Transitions:** Smooth, fluid camera interpolations swinging through atmospheric skycams directly down to chosen spawn points on selection.
* ** Modern & Glassmorphic NUI:** Clean, responsive NUI interface displaying detailed location previews, real-time in-game time, live weather conditions, and active player counts in the area.
* **🏢 Dynamic Apartment & Housing Integration:** Automatically detects and displays player-owned houses, apartments, and last-logged offline locations alongside public spawns.
* **🛡️ Job & Faction Restriction Support:** Configurable spawn points restricted to specific job roles (Police Station for LSPD, Hospital for EMS, Gang HQs, etc.).
* **⚡ Zero Resource Overhead:** Fully asynchronous NUI loading with automatic camera cleanup upon spawning, maintaining a strict `0.00ms` idle consumption.
* **💾 Last Location Memory:** Built-in exact position saving that restores health, armor, routing bucket, and coordinates smoothly without ground clipping.

---

## 📦 Dependencies

Ensure the following resources are installed on your server prior to running this script:

* **Framework:** `qb-core`, `es_extended` (ESX), or Standalone
* **Housing (Optional):** `qb-apartments`, `qb-houses`, `ps-housing`, or `ox_doorlock`
* **UI / Utility:** `ox_lib`

---

## ⚙️ Installation

1. Download or clone the repository into your server's resources directory:
   ```bash
   git clone [https://github.com/YOUR_USERNAME/vater-spawnselector.git](https://github.com/YOUR_USERNAME/vater-spawnselector.git)
