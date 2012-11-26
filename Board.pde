import themidibus.*;

Board brd;
int xpos;

MidiBus myBus; // The MidiBus


class Board{
  float[][] cells, influence; //cells - velocity of each cell, influence - where is that velocity going
  boolean[][] playedstep; //did this square play a note in this step
  int cols, rows; // dimensions
  int curstep; //current step being played 
  float decay = 0.4; // decay
  float influrate = 34; // the intensity of the influence
  int[] sounds; // sounds in the midi table
  int bpm = 120; //beats per minute!
  boolean locked[]; // says if that line is locked and protected from decay effects
  float timepassed; // the time that passed between the current frame and the previous frame.
  
  Board(int _cols, int _rows){
    cols = _cols;
    rows = _rows;
    curstep = 0;
    cells = new float[cols][rows];
    influence = new float[cols][rows];
    playedstep = new boolean[cols][rows];
    sounds = new int[rows];
    locked = new boolean[rows];
    timepassed = millis();
    normalSounds();
    for(int x=0; x<cols; x++){
      for (int y=0; y<rows; y++){
        cells[x][y] = int(random(0,0));
        influence[x][y] = 0;
        playedstep[x][y] = false;
        locked[y]=false;
      }
    }
  }
  
  void toggleLock(int row){
    locked[row] = !locked[row];
  }
  
  void randomSounds(){ //randomize the sounds being played
    for (int i=0; i<rows; i++){
      sounds[i] = int(random(1,80));
    }
    println("Randomized Sounds");
  }
  
  void normalSounds(){ //normalize the sounds being played - octave
    for (int i=0; i<rows; i++){
      sounds[i] = i+60;
    }
    println("Normalized Sounds");
  }
  
  void update(){
    vert();
    int step = int(float(xpos)/width*cols);
    if (step != curstep){
      for (int i=0; i<rows; i++){
        playedstep[curstep][i]=false;
      }
      curstep=step;
     }
    
    for(int x=0; x<cols; x++){
      for (int y=0; y<rows; y++){
        if(!locked[y]){
          if (cells[x][y]>0){
          cells[x][y] -= decay;
          } else {
            cells[x][y] = 0;
          }
          if(cells[x][y]<120){
            cells[x][y] += influence[x][y];
          }
        }
      }
    }
     
  }
  
  void vert(){ //vertical sequence position display
    strokeWeight(4);  
    stroke(#aaaaaa);
    float pixelspermili = float(bpm*(width/cols))/60000;
    xpos = int(pixelspermili*millis())%width;
    line(xpos,0,xpos,height);
  }
  
  void displaycirc(float siz, float px, float py, float margin){
    noFill();
    strokeWeight(3);
    for (int i=int(siz); i>0; i-=10){   
      stroke(map(i,0,200,0,60),150,200,200); 
      ellipse(px+random(-margin,margin),py+random(-margin,margin),i+random(-margin,margin),i+random(-margin,margin));
    }
  }
  
  void influ(float px, float py){
    int x = int(px/width*cols);
    int y = int(py/height*rows);
    
    x = constrain(x,0,cols-1);
    y = constrain(y,0,rows-1);    
    
    for(int ax=0; ax<cols; ax++){
      for (int ay=0; ay<rows; ay++){
        influence[ax][ay] =0;
      }
    }
     influence[x][y] = influrate;
    
  }
  
  void influmatrix(boolean[][] mat){
    for(int i=0; i<cols; i++){
      for (int t=0; t<rows; t++){
        if (mat[i][t]){
          influence[i][t] = influrate;
        } else {
          influence[i][t] = 0;
        }
      }
    }
  }
  
  void clearBoard(){
    for(int i=0; i<cols; i++){
      for (int t=0; t<rows; t++){
        cells[i][t] = 0;
      }
    }
  }
    
    

  
  void display(){
    strokeWeight(1);

        stroke(#888888);
        int xgaps = width/cols;
        int ygaps = height/rows;
        for (int i=1; i<cols; i++){
          line(i*xgaps,0,i*xgaps,height);
        }
        for (int i=1; i<rows; i++){
          line(0,i*ygaps,width,i*ygaps);    
        }
        noStroke();
        for(int x=0; x<cols; x++){
          for (int y=0; y<rows; y++){

            fill(0,0,190,200);
             text(x+"x"+y+"\n"+influence[x][y]+"\n"+cells[x][y]+"\n"+playedstep[x][y], x*xgaps+5, y*ygaps+16);
             if (int(float(xpos)/width*cols)==x){ // if this is the current active step
               noStroke();
                fill(20,130,190,150);
               rect(x*xgaps, (1+y)*ygaps-5,xgaps,4);
               if(cells[x][y]>5){ // if this step is actually being played
                 fill(160,130,190,150);
                 noStroke();
                 rect(x*xgaps, (1+y)*ygaps-25,xgaps,15);
                 if (!playedstep[x][y]){ // if this step already played in this iteration
                   playedstep[x][y] = true;
                   myBus.sendNoteOn(9,sounds[y],int(cells[x][y]));
                   myBus.sendNoteOff(9,sounds[y],0);
                 }
               }
                 
             }
            //   displaycirc(cells[x][y],x*xgaps+(xgaps/2),y*ygaps+(ygaps/2),4);
            fill(90,180,180,180);
            ellipse(x*xgaps+(xgaps/2),y*ygaps+(ygaps/2), cells[x][y],cells[x][y]);

            }
          }        
  }  
}
  



