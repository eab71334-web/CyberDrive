// Example firmware: Arduino/ESP + HM-10 (BLE) + L298N motor driver.
// App commands: F B L R S (drive/stop), 1-9 speed, W/w lights, V horn.
#include <SoftwareSerial.h>
SoftwareSerial ble(2, 3); // RX, TX  <-> HM-10 TX, RX

const int ENA = 5, IN1 = 6, IN2 = 7;   // left motor
const int ENB = 10, IN3 = 8, IN4 = 9;  // right motor
const int LIGHT = 4, HORN = 11;
int spd = 180;

void drive(int l, int r) {
  digitalWrite(IN1, l > 0); digitalWrite(IN2, l < 0);
  digitalWrite(IN3, r > 0); digitalWrite(IN4, r < 0);
  analogWrite(ENA, l ? spd : 0); analogWrite(ENB, r ? spd : 0);
}

void setup() {
  ble.begin(9600);
  int pins[] = {ENA, IN1, IN2, ENB, IN3, IN4, LIGHT, HORN};
  for (int p : pins) pinMode(p, OUTPUT);
}

void loop() {
  if (!ble.available()) return;
  char c = ble.read();
  switch (c) {
    case 'F': drive(1, 1); break;
    case 'B': drive(-1, -1); break;
    case 'L': drive(-1, 1); break;
    case 'R': drive(1, -1); break;
    case 'S': drive(0, 0); break;
    case 'W': digitalWrite(LIGHT, HIGH); break;
    case 'w': digitalWrite(LIGHT, LOW); break;
    case 'V': tone(HORN, 800, 200); break;
    default:
      if (c >= '1' && c <= '9') spd = map(c - '0', 1, 9, 80, 255);
  }
}
