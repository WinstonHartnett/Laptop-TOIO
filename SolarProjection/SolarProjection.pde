/**
 * This is a simple example of how to use the Keystone library.
 *
 * To use this example in the real world, you need a projector
 * and a surface you want to project your Processing sketch onto.
 *
 * Simply drag the corners of the CornerPinSurface so that they
 * match the physical surface's corners. The result will be an
 * undistorted projection, regardless of projector position or
 * orientation.
 *
 * You can also create more than one Surface object, and project
 * onto multiple flat surfaces using a single projector.
 *
 * This extra flexbility can comes at the sacrifice of more or
 * less pixel resolution, depending on your projector and how
 * many surfaces you want to map.
 */

import deadpixel.keystone.*;

Keystone ks;
CornerPinSurface surface;

PGraphics offscreen;

int[] rotationPeriod = new int[8]; //[sun, mercury, venus, earth, mars, earth_moon, mars_moon_1, mars_moon_2];
int[] orbitalPeriod = new int[8]; //[sun, mercury, venus, earth, mars, earth_moon, mars_moon_1, mars_moon_2];
int[] eccentricity = new int[8]; //[sun, mercury, venus, earth, mars, earth_moon, mars_moon_1, mars_moon_2];
int[] distanceFromSun = {0, 1, 2, 3, 4, 5, 6, 7}; //[sun, mercury, venus, earth, mars, earth_moon, mars_moon_1, mars_moon_2];
float centerOfRotationX = 725;
float centerOfRotationY = 475;
float mercDistanceToSun = 150;
float mercSpeed = (float)Math.PI/100;
float mercRadius = 75; //Replace this number
float radian = mercSpeed * 1; //1 replaced for timeInterval
float drawX = centerOfRotationX + mercDistanceToSun * (float)Math.cos(radian);
float drawY = centerOfRotationY + mercDistanceToSun * (float)Math.sin(radian);
float timeInterval =0;


void setup() {
  // Keystone will only work with P3D or OPENGL renderers,
  // since it relies on texture mapping to deform
  size(800, 800, P3D);

  ks = new Keystone(this);
  surface = ks.createCornerPinSurface(400, 300, 20);

  // We need an offscreen buffer to draw the surface we
  // want projected
  // note that we're matching the resolution of the
  // CornerPinSurface.
  // (The offscreen buffer can be P2D or P3D)
  offscreen = createGraphics(500, 500, P3D);
}

void draw() {

  // Convert the mouse coordinate into surface coordinates
  // this will allow you to use mouse events inside the
  // surface from your screen.
  PVector surfaceMouse = surface.getTransformedMouse();

  // Draw the scene, offscreen
  offscreen.beginDraw();
  offscreen.background(255);
  offscreen.fill(0, 255, 0);
  offscreen.ellipse(surfaceMouse.x, surfaceMouse.y, 75, 75);
  offscreen.endDraw();

  // most likely, you'll want a black background to minimize
  // bleeding around your projection area
  background(0);

  // render the scene, transformed using the corner pin surface
  surface.render(offscreen);
  fill(253, 184, 19);  // Sun RGB
  ellipse(725, 475, 75, 75); //Sun
  
  radian = mercSpeed * timeInterval; //1 replaced for timeInterval
  drawX = centerOfRotationX + mercDistanceToSun * (float)Math.cos(radian);
  drawY = centerOfRotationY + mercDistanceToSun * (float)Math.sin(radian);
  
  fill(183, 184, 185);  //Mercury RGB
  ellipse(drawX, drawY, 50, 50); //Mercury
  timeInterval += 1;
  
}

void keyPressed() {
  switch(key) {
  case 'c':
    // enter/leave calibration mode, where surfaces can be warped
    // and moved
    ks.toggleCalibration();
    break;

  case 'l':
    // loads the saved layout
    ks.load();
    break;

  case 's':
    // saves the layout
    ks.save();
    break;
  }
}