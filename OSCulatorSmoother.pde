// Made by Mathias Olsson

// Receives Wii input from OSCulator
// Pitch, roll, yaw and acceleration 
// Smooths the values before forwarding them

import oscP5.*;
import netP5.*;
OscP5 oscP5;
NetAddress dest;

// CHANGE THIS TO MATCH YOUR SETUP
final String oscInputPath = "/wii/3/accel/pry";
final int oscInputPort = 12000;
final String oscOutputPath = "/wek/inputs";
final int oscOutputPort = 6448;

final int numSmoothValues = 10;
float[] pitchArray = new float[numSmoothValues];
float[] rollArray = new float[numSmoothValues];
float[] yawArray = new float[numSmoothValues];
final int numRMSValues = 10;
float[] accelerationArray = new float[numRMSValues];

float currentSmoothPitch = 0;
float currentSmoothRoll = 0;
float currentSmoothYaw = 0;
float currentRMSAcceleration = 0;

PFont myFont;

void setup() {
  //Initialize OSC communication
  oscP5 = new OscP5(this,oscInputPort); //listen for OSC messages on 
  dest = new NetAddress("localhost",oscOutputPort); //send messages back to Wekinator on port 6448, localhost (this machine) (default)
  
  size(400,400, P3D);
  smooth();
  background(255);
  
  myFont = createFont("Arial", 14);
}

void draw() {
  frameRate(30);
  background(255, 255, 255);
  drawText();
      
  stroke(0);
  fill(255);

}

//This is called automatically when OSC message is received
void oscEvent(OscMessage theOscMessage) {
    if (theOscMessage.checkAddrPattern(oscInputPath) == true) {
      final float pitch = theOscMessage.get(0).floatValue();
      final float roll = theOscMessage.get(1).floatValue();
      final float yaw = theOscMessage.get(2).floatValue();
      final float acceleration = theOscMessage.get(3).floatValue();
      
      float smoothPitch = pitch;
      float smoothRoll = roll;
      float smoothYaw = yaw;
      for (int i = 0; i < numSmoothValues-1; i++) {
        pitchArray[i] = pitchArray[i+1];
        smoothPitch += pitchArray[i];
        rollArray[i] = rollArray[i+1];
        smoothRoll += rollArray[i];
        yawArray[i] = yawArray[i+1];
        smoothYaw += yawArray[i];
      }
      pitchArray[numSmoothValues-1] = pitch;
      currentSmoothPitch = round((smoothPitch/numSmoothValues)*100)/100.0;
      rollArray[numSmoothValues-1] = roll;
      currentSmoothRoll = round((smoothRoll/numSmoothValues)*100)/100.0;
      yawArray[numSmoothValues-1] = yaw;
      currentSmoothYaw = round((smoothYaw/numSmoothValues)*100)/100.0;
      
      float RMSAcceleration = acceleration*acceleration;
      for (int i = 0; i < numRMSValues-1; i++) {
        accelerationArray[i] = accelerationArray[i+1];
        RMSAcceleration += accelerationArray[i]*accelerationArray[i];
      }
      accelerationArray[numRMSValues-1] =  acceleration;
      currentRMSAcceleration = round(sqrt(RMSAcceleration/numRMSValues)*100)/100.0;
      
      sendOsc();
    } 
}

void sendOsc() {
  OscMessage msg = new OscMessage(oscOutputPath);
  msg.add((float)currentSmoothPitch); 
  msg.add((float)currentSmoothRoll);
  msg.add((float)currentSmoothYaw);
  msg.add((float)currentRMSAcceleration);
  oscP5.send(msg, dest);
}

void drawText() {
    stroke(0);
    textFont(myFont);
    textAlign(LEFT, TOP); 
    fill(0, 0, 255);

    text("Receives OSC messages from OSCulator", 10, 10);
    String msg = "Listening for 4 OSC message " + oscInputPath + ", port " + str(oscInputPort);
    text(msg, 10, 30);
    msg = "Sending 4 OSC message " + oscOutputPath + ", port " + str(oscOutputPort);
    text(msg, 10, 50);
    msg = "Smooth pitch=" + str(currentSmoothPitch);
    text(msg,10,160);
    msg = "Smooth yaw=" + str(currentSmoothYaw);
    text(msg,10,180);
    msg = "Smooth roll=" + str(currentSmoothRoll);
    text(msg,10,200);
    msg = "RMS acceleration=" + str(currentRMSAcceleration);
    text(msg,10,220);
}