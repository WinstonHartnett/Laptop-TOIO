import oscP5.*;
import netP5.*;
import deadpixel.keystone.*;

//constants
//The soft limit on how many toios a laptop can handle is in the 10-12 range
//the more toios you connect to, the more difficult it becomes to sustain the connection
int nCubes = 12;
int cubesPerHost = 12;
int maxMotorSpeed = 115;
int xOffset;
int yOffset;

int[] matDimension = {45, 45, 455, 455};

Keystone ks;
CornerPinSurface surface;
PGraphics offscreen;

//for OSC
OscP5 oscP5;
//where to send the commands to
NetAddress[] server;

//we'll keep the cubes here
Cube[] cubes;

final int BUTTON_THRESHOLD = 500;
int BUTTON_LAST_PRESS = 0;
int[] pausePosition = {};

// Planet state stuff (don't edit)
final float SUN_GRAV_PARAMETER   = 0.0002958844704;        // AU^3/d^2
final float EARTH_GRAV_PARAMETER = 0.000000000888768273;   // AU^(3)/d^2
final float MARS_GRAV_PARAMETER  = 0.00000000009547681253; // AU^(3)/d^2

final float P_CORRECT = 1.0;
final float I_CORRECT = 0.1;
final float D_CORRECT = 0.0;

float currentGravParameter = SUN_GRAV_PARAMETER; // TODO
float time = 0.0; // days

float error_i = 0.0;
float error_d = 0.0;

boolean paused = false;

/////////////////////////////////////////////////////////////////////////////////////////
// Planetary configuration
/////////////////////////////////////////////////////////////////////////////////////////

Body sun     = new Body("Sun",     null, 0.0,  0.0,     0.0, 24.47, 0.0, SUN_GRAV_PARAMETER);
Body mercury = new Body("Mercury",  sun, 0.39, 0.206,  88.0,  59.0, 0.0, SUN_GRAV_PARAMETER);
Body venus   = new Body("Venus",    sun, 0.76, 0.007, 225.0, 243.0, 0.0, SUN_GRAV_PARAMETER);
Body earth   = new Body("Earth",    sun,       1.00, 0.017,  365.0, 1.0, 0.0, SUN_GRAV_PARAMETER);
Body mars    = new Body("Mars",     sun,       1.52, 0.093,  687.0, 1.0, 0.0, SUN_GRAV_PARAMETER);
Body moon    = new Body("Moon",   earth,    0.00256, 0.055,   27.0, 0.0, 0.0, EARTH_GRAV_PARAMETER); 
Body phobos  = new Body("Phobos",  mars, 0.00006268, 0.0151, 0.319, 0.0, 0.0, MARS_GRAV_PARAMETER);
Body deimos  = new Body("Deimos",  mars, 0.00015682, 0.00033, 1.25, 0.0, 0.0, MARS_GRAV_PARAMETER);

// first element is the orbited body
Body[][] bodiesConfig = {
  { sun, mercury, venus, earth, mars },
  { earth, moon },
  { mars, phobos, deimos },
};

Body[] bodies = bodiesConfig[0]; // current bodies being displayed

// Dec. 28, 2022

/////////////////////////////////////////////////////////////////////////////////////////
// Toio configuration
/////////////////////////////////////////////////////////////////////////////////////////

// Maximum speed (in board units/s) that the Toio can move at.
float maxSpeed = 50;            // board units/s
// All orbits will be scaled such that the largest orbit's maximum distance from the sun
// matches this.
float maxOrbitalDistance = 340; // board units


// {x, y} center of the mat
int[] matCenter = {
  matDimension[2] - ((matDimension[2] - matDimension[0]) / 2),
  matDimension[3] - ((matDimension[3] - matDimension[1]) / 2)
};

/////////////////////////////////////////////////////////////////////////////////////////

//void settings() {
//  size(1000, 1000, P3D); //Added capability with P3D servers for projection mapping
//}
PImage img_mer;
PImage img_ven;
PImage img_ear;
PImage img_mar;
PImage img_sun;
PImage star;
String[] names = new String[4];
float i_sun = 0;

void setup() {  
  //launch OSC sercer
  oscP5 = new OscP5(this, 3333);
  server = new NetAddress[1];
  server[0] = new NetAddress("127.0.0.1", 3334);

  //create cubes
  cubes = new Cube[nCubes];
  for (int i = 0; i< nCubes; ++i) {
    cubes[i] = new Cube(i);
  }
  names[0] = "Mercury";
  names[1] = "Venus";
  names[2] = "Earth";
  names[3] = "Mars";
  xOffset = matDimension[0] - 45;
  yOffset = matDimension[1] - 45;

  //do not send TOO MANY PACKETS
  //we'll be updating the cubes every frame, so don't try to go too high
  frameRate(30);
  
  size(800, 600, P3D);
  img_mer = loadImage("mercury.png");
  img_ven = loadImage("venus.png");
  img_ear = loadImage("earth.png");
  img_mar = loadImage("mars.png");
  img_sun = loadImage("sun.png");
  star = loadImage("night.png");
  ks = new Keystone(this);
  surface = ks.createCornerPinSurface(405, 405, 20);
  
  offscreen = createGraphics(405, 405, P3D);
  
  //img = load("EmptySpace.jpeg");

  //pausePosition = new int[] { cubes[0].x, cubes[0].y };
  cubes[0].led(100000000, 0, 255, 0);

  cubes[1].target(60, 60, 0);
  cubes[2].target(60, 300, 0);
  cubes[3].target(300, 60, 0);
  cubes[4].target(300, 300, 0);
}

void draw() {
  //START TEMPLATE/DEBUG VIEW
//  background(0);// black background
  long now = System.currentTimeMillis();
  
  PVector surfaceMouse = surface.getTransformedMouse();
  

  //draw the "mat"
  //rect(matDimension[0] - xOffset, matDimension[1] - yOffset, matDimension[2] - matDimension[0], matDimension[3] - matDimension[1]);
     //Draw the scene, offscreen, i.e. the projection mapping part
  
  

  //draw the cubes
  //for (int i = 0; i < nCubes; i++) {
  //  cubes[i].checkActive(now);
    
  //  if (cubes[i].isActive) {
  //    pushMatrix();
  //    translate(cubes[i].x - xOffset, cubes[i].y - yOffset);
  //    fill(0);
  //    textSize(15);
  //    text(i, 0, -20);
  //    noFill();
  //    rotate(cubes[i].theta * PI/180);
  //    rect(-10, -10, 20, 20);
  //    line(0, 0, 20, 0);
  //    popMatrix();
  //  }
  //}

  //END TEMPLATE/DEBUG VIEW

  //insert code here

  /////////////////////////////////////////////////////////////////////////////////////////////////////////

  if (millis() - BUTTON_LAST_PRESS > BUTTON_THRESHOLD) {
    // Toggle the pause state.
    if (cubes[0].buttonDown) {
      paused = !paused;

      BUTTON_LAST_PRESS = millis();

      if (paused) {
        cubes[0].led(1000000, 255, 0, 0);
        cubes[0].midi(50, 50, 100);
      } else {
        cubes[0].led(1000000, 0, 255, 0);
        cubes[0].midi(50, 65, 100);
      }

      if (cubes[0].isActive) {
        pausePosition = new int[] { cubes[0].x, cubes[0].y };
      } else {
        pausePosition = null;
      }
    }

    // Handle double-tapping planet selection.
    if (paused) {
      if (cubes[0].doubleTap) {
        bodies = bodiesConfig[0];
        cubes[0].midi(50, 65, 100);
        BUTTON_LAST_PRESS = millis();
      }

      for (int i = 1; i < cubes.length; i++) {
        if (cubes[i].doubleTap) {
          if (i >= bodies.length) {
            break;
          }

          // find the corresponding planet index in the current view
          Body body = bodies[i];

          boolean foundBody = false;

          // set the new body config
          for (int b = 0; b < bodiesConfig.length; b++) {
            if (bodiesConfig[b][0] == body) {
              bodies = bodiesConfig[b];
              foundBody = true;
            }
          }

          if (!foundBody) {
            cubes[i].midi(100, 20, 100);
          } else {
            cubes[i].midi(100, 65, 100);
          }

          BUTTON_LAST_PRESS = millis();
        }
      }
    }
  }

  ////////////////////////////////////////////////////////////////////////////////////////////////////////
  // Identifying movement constraints
  ////////////////////////////////////////////////////////////////////////////////////////////////////////

  // Identify the maximum velocity, so that we can scale orbital velocities according
  // to the Toio's maximum functional velocity. 
  float maxBodiesVelocity  = 0.0;
  float maxBodiesDistance  = 0.0;

  for (int i = 1; i < bodies.length; i++) { // skip the central body
    maxBodiesVelocity  = max(maxBodiesVelocity,  bodies[i].maxVelocity());
    maxBodiesDistance  = max(maxBodiesDistance,  bodies[i].maxDistance());
  }

  float coordsScale = maxOrbitalDistance / maxBodiesDistance;
  float timeScale   = (maxSpeed / (maxBodiesVelocity * coordsScale));

  float timeStep = (1.0 / 30.0) * timeScale; // essentially 1 second = 1 day

  ////////////////////////////////////////////////////////////////////////////////////////////////////////
  // Toio Movement
  ////////////////////////////////////////////////////////////////////////////////////////////////////////

  if (!paused) {
    time += timeStep;
  } else {
    if (cubes[0].isActive) {
      if (pausePosition != null) {
        int[] diff = { pausePosition[0] - cubes[0].x, pausePosition[1] - cubes[0].y };

        float mag = sqrt(pow(diff[0], 2) + pow(diff[1], 2)) * 0.001 * timeScale;

        if (diff[1] < 0) {
          time -= mag;
        } else {
          time += mag;
        }
      } else {
        pausePosition = new int[] { cubes[0].x, cubes[0].y };
      }
    } else {
      pausePosition = null;
    }
  }

  //println("[time] " + time);

  println("[time] " + time);

  offscreen.beginDraw();
  offscreen.background(255);
  offscreen.image(star, 0, 0, 450, 450);
  offscreen.pushMatrix();
  offscreen.translate(202.5, 202.5);
  i_sun = i_sun - 0.01;
  offscreen.imageMode(CENTER);
  offscreen.rotate(i_sun);
  offscreen.image(img_sun, 0, 0, 40, 40);
  offscreen.popMatrix();
  offscreen.imageMode(CORNER);
  offscreen.fill(0, 255, 0);

  for (int i = 1; i < bodies.length; i++) {
    Body body = bodies[i];
    Cube cube = cubes[i];

    float[] nextRelativePose  = body.kepler(time);
    float   nextRelativeX     = nextRelativePose[0];
    float   nextRelativeY     = nextRelativePose[1];
    float   nextRelativeTheta = nextRelativePose[2] * (180.0 / PI) % 360;

    // Next Toio target position...
    float[] nextPose = {
      matCenter[0] + (nextRelativeX * coordsScale),
      matCenter[1] - (nextRelativeY * coordsScale),
      nextRelativeTheta,
      nextRelativePose[3] * coordsScale * timeScale,
      nextRelativePose[4] * coordsScale * timeScale,
    };

    float positionError =
      sqrt(pow(cube.targetedX - cube.x, 2) + pow(cube.targetedY - cube.y, 2));
    float nextVelocity = positionError * P_CORRECT;

    println(
      "[pose "
      + i
      + "] x: "    + round(nextPose[0])
      + " y: "     + round(nextPose[1])
      + " theta: " + round(nextPose[2])
      + " vx: "    + nextPose[3]
      + " vy: "    + nextPose[4]
    );
    if(i == 0){
      offscreen.pushMatrix();
      offscreen.translate(nextPose[0]-55, nextPose[1]-55);
      offscreen.imageMode(CENTER);
      offscreen.rotate(i_sun);
      offscreen.image(img_mer, 0, 0, 20, 20);
      offscreen.popMatrix();
      offscreen.imageMode(CORNER);
    }
    if(i == 1){
      offscreen.pushMatrix();
      offscreen.translate(nextPose[0]-55, nextPose[1]-55);
      offscreen.imageMode(CENTER);
      offscreen.rotate(-0.05 * i_sun);
      offscreen.image(img_ven, 0, 0, 20, 20);
      offscreen.popMatrix();
      offscreen.imageMode(CORNER);
    }
    if(i == 2){
      offscreen.pushMatrix();
      offscreen.translate(nextPose[0]-55, nextPose[1]-55);
      offscreen.imageMode(CENTER);
      offscreen.rotate(timeScale*i_sun);
      offscreen.image(img_ear, 0, 0, 20, 20);
      offscreen.popMatrix();
      offscreen.imageMode(CORNER);
    }
    if(i == 3){
      offscreen.pushMatrix();
      offscreen.translate(nextPose[0]-55, nextPose[1]-55);
      offscreen.imageMode(CENTER);
      offscreen.rotate(timeScale*i_sun);
      offscreen.image(img_mar, 0, 0, 20, 20);
      offscreen.popMatrix();
      offscreen.imageMode(CORNER);
    }

    offscreen.text(names[i], nextPose[0] -40, nextPose[1] -40);

    //   void target(int control, int timeout, int mode, int maxspeed, int speedchange,  int x, int y, int theta) {
    cube.target(
      0,
      100,
      0,
      (int)(nextVelocity),
      0,
      (int)nextPose[0],
      (int)nextPose[1],
      (int)nextPose[2]
    );
  }
    
  offscreen.ellipse(surfaceMouse.x, surfaceMouse.y, 75, 75);
  offscreen.endDraw();
  background(0);
  surface.render(offscreen);
}
