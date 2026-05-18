# Project API Requirements

This document outlines the API endpoints and data requirements for the **Order Bite** (gc_any_order) application, specifically focusing on the updated Settings section and core order management.

---

## 1. Authentication API
Used for restaurant login and session management.

- **Endpoint:** `/api/restaurantmaster/restologin`
- **Method:** `POST`
- **Headers:** `Content-Type: application/json`
- **Request Body:**
  ```json
  {
    "email": "user@example.com",
    "password": "yourpassword"
  }
  ```
- **Response:** Returns restaurant metadata (Store ID, Name, etc.) on success.

---

## 2. Server Settings (Order Management)
These APIs are used to synchronize orders and update their status. The base URL (IP and Port) is configurable in the application settings.

### 2.1 Fetch Pending Orders
- **Endpoint:** `/api/v1/pendingorder`
- **Method:** `GET`
- **Query Parameters:**
  - `a`: Restaurant/Store ID
  - `u`: Username (Email)
  - `p`: Password
- **Response Format:** A sequence of orders delimited by `#` and data fields separated by `;`.
  - *Example:* `#StoreName;Date;Type;OrderNo;...#`

### 2.2 Confirm/Update Order Status
Used for accepting orders with a specific time delay or updating status (Rejected/Delivered).
- **Endpoint:** `/api/v1/confirmorder`
- **Method:** `GET`
- **Query Parameters:**
  - `a`: Restaurant ID
  - `o`: Order Number
  - `ak`: Action/Status (e.g., `Accepted`, `Rejected`)
  - `m`: Message/Minutes (e.g., `15_ok` for accepted with 15 mins)
  - `dt`: Time string (e.g., `00:15:00`)
  - `u`: Username
  - `p`: Password

---

## 3. FCM (Push Notification) Settings
The following requirements are identified for Firebase Cloud Messaging integration.

### 3.1 Device Token Registration
- **Target URL:** Configurable in FCM Settings.
- **Method:** `POST`
- **Content-Type:** `application/json`
- **Purpose:** Registers the device FCM token with the backend to receive real-time push notifications.

### 3.2 Required Firebase Metadata
To ensure FCM functionality, the following must be provided in the settings UI:
- **App ID:** Unique identifier for the Firebase app.
- **Project ID:** Firebase project identifier.
- **API Key:** Firebase web API key.
- **Topic:** Subscription topic for the restaurant (e.g., `restaurant_1`).

---

## 4. Local Settings State
The following settings are currently stored locally via `SharedPreferences` but may require remote synchronization in future updates:

| Category | Key | Description |
| :--- | :--- | :--- |
| **Printer** | `printerType` | Bluetooth / Built-in / No Printer |
| **Printer** | `paperSize` | 58mm / 80mm |
| **Printer** | `autoPrint` | Boolean toggle for automatic receipt printing |
| **Printer** | `selectedDeviceMac` | Captured MAC address for Bluetooth printers |
| **Server** | `apiUrl` | Base URL for all `/api/v1/*` requests |
| **General** | `iniVersion` | Version tracker for remote configuration files |
