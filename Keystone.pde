Keystone k;

class Keystone {
  PVector z0; //origin
  PVector z1; //x
  PVector z2; //y
  private float phi=0f;
  private float theta=0f;
  float[][] t;
  private float stretchX=0.5;
  private float stretchY=0.5;
  int[] silkScreenLUT;

  public Keystone() {
    z0= new PVector(80,12,973);//(0,0,1000);//(140.0,38.0,980.0); //(0, 0, 0); //WAS 96
    z1= new PVector(504,26,978);//(640,0,1000);//(516.0,18.0,981.0); //(1, 0, 0);
    z2= new PVector(80,260,978);//(0,480,1000); //(90.0,294.0,976.0); //(0, 1, 0); (174.0, 396.0, 846.0); //WAS 96
    t = new float[3][3];
    silkScreenLUT = new int[w*h];
    init();
  }

  void init() {
    calculateInclination();
    populateMatrix();
    stretchX = w/z0.dist(z1);
    stretchY = h/z0.dist(z2);
    populateLUT();
    println("Stretch: "+stretchX+","+stretchY);
    print("|"+t[0][0]+","+t[0][1]+","+t[0][2]+"|\n"+"|"+t[1][0]+","+t[1][1]+","+t[1][2]+"|\n"+"|"+t[2][0]+","+t[2][1]+","+t[2][2]+"|\n");
  }

  void setOrigin(PVector origin) {
    z0=origin;
  }

  void setX(PVector x) {    
    z1=x;
  }
  void setY(PVector y) { 
    z2=y;
  }
  PVector correct(PVector v) {
    PVector u = new PVector(
    (v.x*t[0][0]+v.y*t[0][1]+v.z*t[0][2])*stretchX + z0.x, 
    (v.x*t[1][0]+v.y*t[1][1]+v.z*t[1][2])*stretchY + z0.y, 
    (v.x*t[2][0]+v.y*t[2][1]+v.z*t[2][2]) + z0.z
      );
    return u;
  }

  PVector rotateBack(PVector v) {
    PVector uTranspose = new PVector(
    (v.x*t[0][0]+v.y*t[1][0]+v.z*t[2][0])*stretchX - z0.x, 
    (v.x*t[0][1]+v.y*t[1][1]+v.z*t[2][1])*stretchY - z0.y, 
    (v.x*t[0][2]+v.y*t[1][2]+v.z*t[2][2]) - z0.z
      );
    return uTranspose;
  }

  private void calculateInclination() {
    PVector absz1 = PVector.sub(z1, z0);
    PVector absz2 = PVector.sub(z2, z0);
    theta = -acos( (absz1.z * 1.0f) / absz1.mag() )+HALF_PI;
    phi   =  acos( (absz2.z * 1.0f) / absz2.mag() )-HALF_PI;
    println ("Theta : "+theta+", Phi : "+phi);
  }

  private void populateMatrix() {
    //float[][] temp = {{ cos(theta), ( sin(theta) * cos(phi) ), ( cos(phi) * sin(theta) ) }, { 0, cos(phi), (-sin(phi)) }, { (-sin(theta)), ( sin(phi) * cos(theta) ), ( cos(phi) * cos(theta) ) }};
    float[][] temp = {
      { 
        cos(phi), 0, sin(phi)
        }
      , {
        (sin(theta) * sin (phi)), cos(theta), (-sin(theta) * cos(phi))
        }
      , {
        (-sin(phi) * cos(theta)), sin(theta), (cos(theta) * cos(phi))
        }
      };
      t=temp;
  }

  private void populateLUT() {
    for (int j=0; j<h;j++) {
      for (int i=0;i<w;i++) { 
        silkScreenLUT[i+w*j] = getScreenDepth(new PVector(i, j,0));
      }
    }
  }

  private int getScreenDepth(PVector v) {
    return (int) correct(v).z;
  }
  
  public void reset(){
    z0= new PVector(200.0,100.0,0.0);
    z1= new PVector(1000.0,100.0,0.0);
    z2= new PVector(200.0,800.0,0.0);
    init();
  }
}

