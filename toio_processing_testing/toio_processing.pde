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

PImage img;

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
Planet[] planets = {
  // Planet(float majorAxis, float eccentricity, float period, float periapsis, float gravitationalParameter)
  new Planet(1.0, 0.206, 87.0, PI,  SUN_GRAV_PARAMETER),
  new Planet(2.5, 0.007, 224.0, 0.0, SUN_GRAV_PARAMETER),
};

/////////////////////////////////////////////////////////////////////////////////////////
// Toio configuration
/////////////////////////////////////////////////////////////////////////////////////////

// Maximum speed (in board units/s) that the Toio can move at.
float maxSpeed = 40;            // board units/s
// All orbits will be scaled such that the largest orbit's maximum distance from the sun
// matches this.
float maxOrbitalDistance = 300; // board units

/////////////////////////////////////////////////////////////////////////////////////////

void settings() {
  size(1000, 1000, P3D); //Added capability with P3D servers for projection mapping
}

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

  xOffset = matDimension[0] - 45;
  yOffset = matDimension[1] - 45;

  //do not send TOO MANY PACKETS
  //we'll be updating the cubes every frame, so don't try to go too high
  frameRate(30);
  
  ks = new Keystone(this);
  surface = ks.createCornerPinSurface(400, 300, 20);
  
  img = loadImage("Green_test_square.png");
  
  offscreen = createGraphics(400, 300, P3D);
}

void draw() {
  //START TEMPLATE/DEBUG VIEW
//  background(0);// black background
  stroke(0);
  long now = System.currentTimeMillis();
  
  PVector surfaceMouse = surface.getTransformedMouse();
  

  //draw the "mat"
//  fill(255);
  //rect(matDimension[0] - xOffset, matDimension[1] - yOffset, matDimension[2] - matDimension[0], matDimension[3] - matDimension[1]);
    // Draw the scene, offscreen, i.e. the projection mapping part
  
  background(0);
  

  //draw the cubes
  for (int i = 0; i < nCubes; i++) {
    cubes[i].checkActive(now);
    
    if (cubes[i].isActive) {
      pushMatrix();
      translate(cubes[i].x - xOffset, cubes[i].y - yOffset);
      fill(0);
      textSize(15);
      text(i, 0, -20);
      noFill();
      rotate(cubes[i].theta * PI/180);
      rect(-10, -10, 20, 20);
      line(0, 0, 20, 0);
      popMatrix();
    }
  }

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
  float maxBodiesPerimeter = 0.0;
  float maxBodiesDistance  = 0.0;

  for (int i = 0; i < planets.length; i++) {
    maxBodiesVelocity  = max(maxBodiesVelocity,  planets[i].solver().maxVelocity());
    maxBodiesPerimeter = max(maxBodiesPerimeter, planets[i].solver().perimeter());
    maxBodiesDistance  = max(maxBodiesDistance,  planets[i].solver().maxDistance());
  }

  float coordsScale = maxOrbitalDistance / maxBodiesDistance;
  float timeScale   = (maxSpeed / (maxBodiesVelocity * coordsScale));

  float timeStep = (1.0 / 30.0) * timeScale; // essentially 1 second = 1 day

  println(timeStep);

  ////////////////////////////////////////////////////////////////////////////////////////////////////////
  // Toio Movement
  ////////////////////////////////////////////////////////////////////////////////////////////////////////

  time += timeStep;

  println("[time] " + time);

  for (int i = 0; i < planets.length; i++) {
    Planet planet = planets[i];
    Cube   cube   = cubes[i];

    float[] nextRelativePose  = planet.solver().kepler(time);
    float   nextRelativeX     = nextRelativePose[0];
    float   nextRelativeY     = nextRelativePose[1];
    float   nextRelativeTheta = nextRelativePose[2] * (180.0 / PI) % 360;

    //float[] nextRelativePose  = planet.step();
    //float   nextRelativeTheta = nextRelativePose[2];

    //float positionError =
    //  sqrt(pow(cube.targetedX - cube.x, 2) + pow(cube.targetedY - cube.y, 2));
    //float positionCorrect = positionError * P_CORRECT;

    //// coords system is completely fucked and i can't be bothered
    //if (nextRelativePose[0] < 0) {
    //  // left of y-axis
    //  if (nextRelativePose[1] < 0) {
    //    // below x-axis
    //    nextRelativeTheta = nextRelativeTheta;
    //  } else {
    //    // above x-axis
    //    nextRelativeTheta = 180 - nextRelativeTheta;
    //  }
    //} else {
    //  // right of y-axis
    //  if (nextRelativePose[1] < 0) {
    //    // below x-axis
    //    nextRelativeTheta = 360 - nextRelativeTheta;
    //  } else {
    //    // above x-axis
    //    nextRelativeTheta = 180 - nextRelativeTheta;
    //  }
    //}

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


    offscreen.beginDraw();
    offscreen.background(255);
    offscreen.image(img, 0, 0, 400, 300);
    offscreen.fill(255, 0, 0);
    offscreen.ellipse(surfaceMouse.x, surfaceMouse.y, 75, 75);
    offscreen.fill(0,0,0);
    offscreen.circle(nextPose[0], nextPose[1], 20);
    offscreen.text("planet " + i, nextPose[0] + 15, nextPose[1] + 15);
    offscreen.endDraw();
    
    surface.render(offscreen);
    
    
    

    //float nextToioVelocity =
    //  10 * (planet.solver().instantVelocity(planet.orbit(), currentGravParameter) / maxBodiesVelocity);

    //nextToioVelocity = nextToioVelocity + positionCorrect;
    //nextToioVelocity = min(nextToioVelocity, 40);

    //println(planet.solver().kepler(time));

    ////   void target(int control, int timeout, int mode, int maxspeed, int speedchange,  int x, int y, int theta) {
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
}
