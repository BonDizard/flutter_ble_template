#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// BLE Server Callbacks
class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
    Serial.println("Device connected");
  };

  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
    Serial.println("Device disconnected");
  }
};

// BLE Characteristic Callbacks
class CharacteristicCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pCharacteristic) {
    String value = pCharacteristic->getValue();
    if (value.length() > 0) {
      Serial.println("Received message: " + String(value.c_str()));
    }
  }
};

void setup() {
  Serial.begin(115200);

  BLEDevice::init("ESP32 BLE Server");

  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  BLEService* pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_NOTIFY);
  pCharacteristic->addDescriptor(new BLE2902());
  pCharacteristic->setCallbacks(new CharacteristicCallbacks());

  pService->start();

  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);

  BLEDevice::startAdvertising();
  Serial.println("Waiting for a client connection to receive data...");
}

String createDWINCommand(String vpAddress, float value) {
    char valueBuffer[10];
    snprintf(valueBuffer, sizeof(valueBuffer), "%.2f", value); // Convert float to string with 2 decimal places
    
    String asciiHexString = "";
    for (int i = 0; valueBuffer[i] != '\0'; i++) {
        char hexBuffer[3];
        snprintf(hexBuffer, sizeof(hexBuffer), "%02X", valueBuffer[i]); // Convert char to HEX
        asciiHexString += String(hexBuffer) + " ";
    }

    asciiHexString.trim(); // Fix: This modifies the existing string instead of returning void

    // First command (clear previous data)
    String clearData = "5A A5 35 82 " + vpAddress + " 20 20 20 20 20 20 20 20 20 20";

    // Second command (write new value)
    String newData = "5A A5 08 82 " + vpAddress + " " + asciiHexString;

    return clearData + " " + newData;
}



void loop() {
  if (deviceConnected) {
    int w = random(0, 100);
    int x = random(0, 100);
    int y = random(0, 100);
    int z = random(0, 100);

    String wMessage = createDWINCommand("12 00", w);
    String xMessage = createDWINCommand("15 00", x);
    String yMessage = createDWINCommand("21 00", y);
    String zMessage = createDWINCommand("17 00", z);

    // Send each value separately
    pCharacteristic->setValue(wMessage.c_str());
    pCharacteristic->notify();
    Serial.println("Sent: " + wMessage);
    delay(200);

    pCharacteristic->setValue(xMessage.c_str());
    pCharacteristic->notify();
    Serial.println("Sent: " + xMessage);
    delay(200);

    pCharacteristic->setValue(yMessage.c_str());
    pCharacteristic->notify();
    Serial.println("Sent: " + yMessage);
    delay(200);

    pCharacteristic->setValue(zMessage.c_str());
    pCharacteristic->notify();
    Serial.println("Sent: " + zMessage);
    delay(200);

    // Wait for next update
    delay(1000);
  }

  // Handle disconnection and reconnection
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    Serial.println("Start advertising");
    oldDeviceConnected = deviceConnected;
  }

  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }
}
