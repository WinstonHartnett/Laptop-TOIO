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

class Body {
  private String name;
  private float majorAxis;
  private float eccentricity;
  private float periapsis;
  private float period;
  private float gravParameter;

  Body(String name, float a, float e, float P, float p, float gp) {
    majorAxis = a;
    eccentricity = e;
    period = P;
    periapsis = p;
    gravParameter = gp;
  }

  // returns:
  // - x     (AU)
  // - y     (AU)
  // - theta (rad)
  // - vx    (AU/d)
  // - vy    (AU/d)
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

  float maxVelocity() {
    // when closest to the periapsis
    float[] pose = kepler(0.0);

    return sqrt(pow(pose[3], 2) + pow(pose[4], 2));
  }

  // Ramanujan approximation
  float perimeter() {
    float minorAxis = majorAxis * sqrt(1 - pow(eccentricity, 2));

    return (3 * (majorAxis + minorAxis)) - sqrt((3 * majorAxis + minorAxis) * (majorAxis + 3 * minorAxis));
  }

  // max distance from the focus (the sun or whatever's being orbited)
  float maxDistance() {
    return (2 * majorAxis) - periapsis;
  }
}
