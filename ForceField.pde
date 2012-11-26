
import org.openkinect.*;
import org.openkinect.processing.*;
import hypermedia.video.*;

//Debug
boolean DEBUG = true;
boolean PREVIEW = false;

// Kinect
Kinect kinect;
final int w = 640;
final int h = 480;
int[] depth;

//OpenCV
Blob[] blobs;
int selectedBlob = 0;
OpenCV opencv;

//depth
int mean = 850;
int sigma = 8;
boolean autodepth = true;

//Corner Pin
PImage bufferImage;
float eps = 0;

//Board
boolean[][] controller;
PFont myFont;
PFont debugFont;
//Metric LUT
//float[] depthLookUp = new float[2048];

//Monitor
PFrame f;
Monitor m;



void setup() {
  size(w*2, h*2);
  frame.removeNotify();
  frame.setUndecorated(true);
  k = new Keystone();

  opencv = new OpenCV(this);
  opencv.allocate(w/2, h/2);

  kinect = new Kinect(this);
  kinect.start();
  kinect.enableDepth(true);
  //kinect.processDepthImage(false);
  if (PREVIEW) {kinect.enableRGB(true);}
  PFrame f = new PFrame();
  brd = new Board(16, 8);

  noSmooth();
  frameRate(80);
  colorMode(HSB);

  myFont = createFont("AppleGothic", 8);
  textFont(myFont); 
  
  debugFont = createFont("AppleGothic", 24);

  myBus = new MidiBus(this, -1, "Java Sound Synthesizer");
  myBus.list();
}



void draw () {
  if (DEBUG) {

    background(255);
    fill(0);
    stroke(0);
    strokeWeight(1);

    //Grid
    for (int i=1;i<17;i++) {
      // PVector start = new PVector(i*(width/16), 0);
      // PVector end   = new PVector(i*(width/16), height);
      line(i*(width/16), 0, i*(width/16), height);
    }
    for (int i=1;i<9;i++) {
      line(0, i*(height/8), width, i*(height/8));
    }
    //Status
    String s = "Epsilon: "+eps+", Sigma: "+sigma;//"zero: "+(int)zero.x+" , "+ (int)zero.y + "a: " + Float.toString(a) + " d: " + Float.toString(d) ;
    text(s, 100, 30);


    stroke(255, 0, 0);
    fill(255, 0, 0);
    strokeWeight(4);
  }

  controller=new boolean[16][8];
  bufferImage = createImage(w/2, h/2, RGB);
  bufferImage.loadPixels();
  depth = kinect.getRawDepth();


  //Scan/Draw
  for (int y=0;y<h;y+=2) {
    for (int x=0;x<w;x+=2) {
      int index = x + y*w;
      int rawDepth = depth[index];
      int zone=color(0, 0, 0);
      boolean rangeCondition = (autodepth? ((rawDepth>k.silkScreenLUT[index]+eps) && (rawDepth<k.silkScreenLUT[index]+sigma+eps)) : (rawDepth>(abs(mean-sigma)) && rawDepth < (abs(mean+sigma))));
      if (rangeCondition) {
        zone = depth[index];
        if (DEBUG) {
          PVector v = k.rotateBack(new PVector(x, y, depth[index]));
          point(v.x*2, v.y*2);
        }
      }
      bufferImage.pixels[((int)x/2)+((int)y/2)*bufferImage.width]=zone;
    }
  }

  if (DEBUG) {
    stroke(0, 255, 0);
    fill(0, 255, 0);
  } 

  bufferImage.updatePixels();
  //video
  if (PREVIEW) { 
    PImage img = kinect.getVideoImage();
    img.resize(320,240);
    m.image(img, 0, 0);
    m.redraw();
  }

  //Draw Centroids
  bufferImage.filter(THRESHOLD, .1);
  calculateBlobs();
  for (Blob b : blobs) {
    if (b!=null) {
      PVector cent = k.rotateBack(new PVector(b.centroid.x*2, b.centroid.y*2, depth[b.centroid.x*2 +w*b.centroid.y*2]));
      int boardX = (int)Math.floor(cent.x*(16f/w));
      int boardY = (int)Math.floor(cent.y*(8f/h));
      if (boardX<16 && boardY<8 && boardX>=0 && boardY>=0) {
        controller[boardX][boardY]=true;
      }
      fill(255, 0, 0);
      rect((int)(boardX*(w*2f/16)), ((int)(boardY*(h*2f/8))), 30, 30);
      fill(0, 255, 0);  //remove 
      stroke(0, 255, 0);
      ellipse(cent.x*2, cent.y*2, 50, 50);
    }
  }
  //Draw highlight centroid and XYO
  if (DEBUG) {
    if (blobs.length!=0) {
      noFill(); 
      Blob b= blobs[selectedBlob%blobs.length];
      PVector cent = k.rotateBack(new PVector(b.centroid.x*2, b.centroid.y*2, depth[b.centroid.x*2 +w*b.centroid.y*2]));
      ellipse(cent.x*2, cent.y*2, 80, 80);
      if (PREVIEW) {fill(255,0,0,255); ellipse(b.centroid.x,b.centroid.y,20,20);}
      fill(255,0,0);
      stroke (255,0,0);
      ellipse (k.z0.x*2, k.z0.y*2,30,30);
      ellipse (k.z1.x*2, k.z1.y*2,30,30);
      ellipse (k.z2.x*2, k.z2.y*2,30,30);
  }
  }

  brd.influmatrix(controller);
  if (!DEBUG) {  
    background(#333333);
    brd.update();
    brd.display();
  }

  //Program
  if (!DEBUG) {
    if (mousePressed) {
      brd.influ(mouseX, mouseY);
    }
    if (keyPressed) {
      if (key == 'r') {
        brd.randomSounds();
      }
      if (key == ']') {
        brd.bpm +=1;
        println("BPM is now: "+brd.bpm);
      }
      if (key == '[') {
        brd.bpm -=1;
        println("BPM is now: "+brd.bpm);
      }
    }
  }
}


void calculateBlobs() {
  opencv.copy(bufferImage);
  opencv.threshold(50);
  blobs = opencv.blobs(120, 1000, 4, false, 4);
}




public void keyPressed() {
  switch (keyCode) {
  case UP   :  
    {
      mean+=10; 
      break;
    }
  case DOWN :  
    {
      mean-=10; 
      break;
    } 
  case LEFT :  
    {
      sigma-=2; 
      break;
    }
  case RIGHT:  
    {
      sigma+=2; 
      break;
    }
  }

  switch (key) {
  case 'w' : 
    {
      k.reset();
      break;
    }
  case 's' : 
    {

      break;
    }
  case 'a' : 
    {

      break;
    }
  case 'd' : 
    {
     
      break;
    }
  case 'W': 
    {
      eps+=1;
      break;
    }
  case 'S': 
    {
      eps-=1;
      break;
    }
  case 'A': 
    {
      autodepth=!autodepth;
      break;
    }
  case 'D': 
    {

      break;
    }
    case 'p':
    {if (PREVIEW) {kinect.enableRGB(true);} else {kinect.enableRGB(true);} PREVIEW=!PREVIEW; break;}
  case 'Q': 
    {
      if (DEBUG) {textFont(myFont);} else {textFont(debugFont);}
      DEBUG=(!DEBUG);
      break;
    }
  case 'o':
    {
      if (DEBUG) {
        Blob b = blobs[selectedBlob%blobs.length];
        PVector v = new PVector(b.centroid.x*2, b.centroid.y*2, depth[b.centroid.x+w*b.centroid.y]);
        k.setOrigin(v);
        println("KEYSTONE: origin set at ("+v.x+","+v.y+","+v.z+")");
        break;
      }
    }
  case 'x':
    {
      if (DEBUG) {
        Blob b = blobs[selectedBlob%blobs.length];
        PVector v = new PVector(b.centroid.x*2, b.centroid.y*2, depth[b.centroid.x+w*b.centroid.y]);
        k.setX(v);
        println("KEYSTONE: x set at ("+v.x+","+v.y+","+v.z+")");
        break;
      }
    }
  case 'y':
    {
      if (DEBUG) {
        Blob b = blobs[selectedBlob%blobs.length];
        PVector v = new PVector(b.centroid.x*2, b.centroid.y*2, depth[b.centroid.x+w*b.centroid.y]);
        k.setY(v);
        println("KEYSTONE: y set at ("+v.x+","+v.y+","+v.z+")");
        break;
      }
    }
  case 'O' :
    {
      if (DEBUG) {
        k.init(); 
        println("init");
        break;
      }
    }
  case '-' :
    {
      selectedBlob--; 
      break;
    }
  case '=' :
    {
      selectedBlob++; 
      break;
    }
  }
}


void stop() {
  kinect.quit();
  super.stop();
}

