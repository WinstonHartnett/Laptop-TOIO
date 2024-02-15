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

// Planet state stuff (don't edit)
//final float SUN_GRAV_PARAMETER = 1.327 * pow(10, 20); // m^3/s^2
final float SUN_GRAV_PARAMETER = 0.0002958844704; // AU^3/d^2

final float P_CORRECT = 1.0;
final float I_CORRECT = 0.1;
final float D_CORRECT = 0.0;

float currentGravParameter = SUN_GRAV_PARAMETER; // TODO
float time = 0.0; // days

float error_i = 0.0;
float error_d = 0.0;

/////////////////////////////////////////////////////////////////////////////////////////
// Planetary configuration
/////////////////////////////////////////////////////////////////////////////////////////

// list of planetary bodies being displayed
Body[] bodies = {
  // Planet(float majorAxis, float eccentricity, float period, float periapsis, float gravitationalParameter)
  // - majorAxis: size of ellipse major axis (AU)
  // - period: in days
  // - periapsis: closest distance to orbited object (like the Sun or Earth)
  // - gravitationalParameter: G * (m_1 + m_2)             en.wikipedia.org/wiki/Standard_gravitational_parameter
  new Body("Mercury", 0.39, 0.206,  88.0, 0.0,  SUN_GRAV_PARAMETER),
  new Body("Venus",   0.76, 0.007, 225.0, 0.0, SUN_GRAV_PARAMETER),
  new Body("Earth",   1.00, 0.017, 365.0, 0.0, SUN_GRAV_PARAMETER),
  new Body("Mars",    1.52, 0.093, 687.0, 0.0, SUN_GRAV_PARAMETER),
};

// Dec. 28, 2022

/////////////////////////////////////////////////////////////////////////////////////////
// Toio configuration
/////////////////////////////////////////////////////////////////////////////////////////

// Maximum speed (in board units/s) that the Toio can move at.
float maxSpeed = 50;            // board units/s
// All orbits will be scaled such that the largest orbit's maximum distance from the sun
// matches this.
float maxOrbitalDistance = 340; // board units

/////////////////////////////////////////////////////////////////////////////////////////

//void settings() {
//  size(1000, 1000, P3D); //Added capability with P3D servers for projection mapping
//}
PImage img_mer;
PImage img_ven;
PImage img_ear;
PImage img_mar;
PImage sun;
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
  sun = loadImage("sun.png");
  star = loadImage("night.png");
  ks = new Keystone(this);
  surface = ks.createCornerPinSurface(405, 405, 20);
  
  offscreen = createGraphics(405, 405, P3D);
  
  //img = load("EmptySpace.jpeg");
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

  // {x, y} center of the mat
  int[] matCenter = {
    matDimension[2] - ((matDimension[2] - matDimension[0]) / 2),
    matDimension[3] - ((matDimension[3] - matDimension[1]) / 2)
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////
  // Identifying movement constraints
  ////////////////////////////////////////////////////////////////////////////////////////////////////////

  // Identify the maximum velocity, so that we can scale orbital velocities according
  // to the Toio's maximum functional velocity. 
  float maxBodiesVelocity  = 0.0;
  float maxBodiesDistance  = 0.0;

  for (int i = 0; i < bodies.length; i++) {
    maxBodiesVelocity  = max(maxBodiesVelocity,  bodies[i].maxVelocity());
    maxBodiesDistance  = max(maxBodiesDistance,  bodies[i].maxDistance());
  }

  float coordsScale = maxOrbitalDistance / maxBodiesDistance;
  float timeScale   = (maxSpeed / (maxBodiesVelocity * coordsScale));

  float timeStep = (1.0 / 30.0) * timeScale; // essentially 1 second = 1 day

  ////////////////////////////////////////////////////////////////////////////////////////////////////////
  // Toio Movement
  ////////////////////////////////////////////////////////////////////////////////////////////////////////

  time += timeStep;

  println("[time] " + time);
  offscreen.beginDraw();
  offscreen.background(255);
  offscreen.image(star, 0, 0, 450, 450);
  offscreen.pushMatrix();
  offscreen.translate(202.5, 202.5);
  i_sun = i_sun - 0.01;
  offscreen.imageMode(CENTER);
  offscreen.rotate(i_sun);
  offscreen.image(sun, 0, 0, 40, 40);
  offscreen.popMatrix();
  offscreen.imageMode(CORNER);
  offscreen.fill(0, 255, 0);
  for (int i = 0; i < bodies.length; i++) {
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
