# 🏎️ vater-garage | Advanced & Modern Vehicle Management System

> **vater-garage** is a highly optimized, feature-rich vehicle garage and persistent impound management system designed for FiveM servers. Built with a sleek user experience and ultra-low resource usage, it provides seamless vehicle spawning, storage, state tracking, and garage management for both civilian and job-based workflows.

---

## 🚀 Key Features

* **⚡ Ultra-Optimized Performance:** Runs at a smooth `0.00ms` on idle with zero client-side lag during high server loads.
* ** Modern & Responsive UI:** Clean, modern user interface displaying detailed vehicle specs, engine/body health, fuel levels, and current vehicle status.
* ** Real-Time State Tracking:** Automatically handles vehicle states (Out, Stored, Impounded, Seized) with real-time database syncing to prevent vehicle duplication.
* ** Multi-Garage Support:** Unlimited configurable public, private, job-restricted (Police, Ambulance, Mechanic), and gang garages with unique access levels.
* ** Complex Impound System:** Fully customizable impound mechanics with adjustable retrieval fees, timers, and reason logs managed by law enforcement or mechanic jobs.
* ** Waypoint & Retrieval Assistance:** Built-in vehicle locator that marks your out-of-garage vehicle directly on the GPS map.
* ** Localization & Configuration:** Multi-language support out of the box (`en`, `tr`, etc.) via a user-friendly `config.lua`.

---

## 📦 Dependencies

Ensure the following resources are installed on your server prior to running this script:

* **Framework:** `qb-core` or `es_extended` (ESX)
* **Target System:** `qb-target`, `ox_target`, or standalone 3D text/markers
* **Database:** `oxmysql` or `mysql-async`
* **UI / Utility:** `ox_lib` (or native UI alternative)

---

## ⚙️ Installation

1. Download or clone the repository into your server's resources directory:
   ```bash
   git clone [https://github.com/YOUR_USERNAME/vater-garage.git](https://github.com/YOUR_USERNAME/vater-garage.git)
