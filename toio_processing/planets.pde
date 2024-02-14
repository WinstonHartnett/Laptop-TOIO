int signum(float n) {
  if (n > 0) return 1;
  if (n < 0) return -1;

  return 0;
}

// from: johndcook.com/blog/2021/04/01/efficient-kepler-equation
float solveEccentricAnomaly(float e, float M) {
  float E = 0.0;

  while (true) {
    float fE = M + (e * sin(E));

    if (abs(fE - E) < 0.01) {
      return E;
    } else {
      E = fE;
    }
  }
}

class OrbitSolver {
  //private final float SPEED_MULT = 100.0;

  private float majorAxis;
  private float eccentricity;
  private float periapsis;
  private float period;
  private float gravParameter;

  OrbitSolver(float a, float e, float P, float p, float gp) {
    majorAxis = a;
    eccentricity = e;
    period = P;
    periapsis = p;
    gravParameter = gp;
  }

  float[] kepler(float t) {
    // from wikipedia: Kepler's laws of planetary motion
    float n = (2 * PI) / period;
    float M = n * t;
    float E = solveEccentricAnomaly(eccentricity, M);

    // from wikipedia: true anomaly
    float Beta = eccentricity / (1 + sqrt(1 - pow(eccentricity, 2)));
    float theta = E + 2 * atan((Beta * sin(E)) / (1 - Beta * cos(E)));

    float r = majorAxis * (1 - (eccentricity * cos(E)));
    float x = cos(theta) * r;
    float y = sin(theta) * r;

    float sgpMult = sqrt(gravParameter * majorAxis) / r;
    float vx = sgpMult * -(sin(E));
    float vy = sgpMult * (sqrt(1 - pow(eccentricity, 2)) * cos(E));

    float[] res = { x, y, theta, vx, vy };

    return res;
  }

  //float maxVelocity() {
  //  // when closest to the periapsis
  //}

  //float distance(float orbit) {
  //  float top = majorAxis * (1 - pow(eccentricity, 2));
  //  float bot = 1 - (eccentricity * cos(orbit));

  //  return top / bot;
  //}

  //float stepOrbit(float orbit) {
  //  float inner = orbit + (1 / (SPEED_MULT * pow(distance(orbit), 2)));

  //  return inner % (2 * PI);
  //}

  //float[] stepPosition(float orbit) {
  //  float[] res = {
  //    cos(orbit + periapsis) * distance(orbit),
  //    sin(orbit + periapsis) * distance(orbit),
  //  };

  //  return res;
  //}

  //float tangentAngle(float orbit) {
  //  float a = majorAxis;
  //  float e = eccentricity;

  //  float b = sqrt(pow(a, 2) * (1 - pow(e, 2))); // solve for b using major axis and eccentricity
  //  float slope = -(b * cos(orbit)) / (a * sin(orbit)); // note: orbit == 0 will cause problems
  //  float angle = atan(slope);

  //  return angle;
  //}

//  float instantVelocity(float orbit, float gravParameter) {
//    return sqrt(gravParameter * ((2 / distance(orbit)) - (1 / majorAxis)));
//  }

//  float maxVelocity(float gravParameter) {
//    return instantVelocity(periapsis, gravParameter);
//  }
}

class Planet {
  private OrbitSolver solver;
  //private float orbit;

  Planet(float a, float e, float P, float p, float gp) {
    //assert(o != 0.0);
    solver = new OrbitSolver(a, e, P, p, gp);
    //orbit = o;
  }

  public OrbitSolver solver() {
    return solver;
  }

//  public float orbit() {
//    return orbit;
//  }

  //public float[] step() {
  //  orbit = solver().stepOrbit(orbit);
    
  //  float   nextRelativeTheta = solver().tangentAngle(orbit) * (180 / PI);
  //  float[] nextRelativePos   = solver().stepPosition(orbit);

  //  float[] res = { nextRelativePos[0], nextRelativePos[1], nextRelativeTheta, };

  //  return res;
  //}
}
