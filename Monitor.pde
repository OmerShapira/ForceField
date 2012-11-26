public class Monitor extends PApplet {
    public void setup() {
        size(320, 240);
        noLoop();
    }
    public void draw() {
    }
}

public class PFrame extends Frame {
    public PFrame() {
        setBounds(100,100,320,240);
        m = new Monitor();
        add(m);
        m.init();
        show();
    }
}

