import java.awt.Color;
import java.awt.Container;
import java.awt.Font;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import javax.sound.sampled.LineUnavailableException;
import javax.swing.*;
public class App extends JPanel {
    JFrame frame1 = new JFrame("FLAPPY BIRD 💕❤️🦜🦜🦜");
    JButton button;
    JPanel pan;
    JLabel lab;
    Container con;
    Font tite=new Font("Times New Roman",Font.PLAIN,98);
    App() throws LineUnavailableException{
       
        button  = new JButton();

        button.setBounds(600,290,130,80);
        button.setText("PLAY");
        frame1.getContentPane().setBackground(Color.cyan);
        button.setBackground(Color.LIGHT_GRAY);
        frame1.setSize(1360,850);  
        frame1.setVisible(true); 
        frame1.add(button);
        frame1.setLayout(null);
        frame1.setResizable(false);
        con=frame1.getContentPane();
        lab = new JLabel("        FLAPPY BIRD");
        pan = new JPanel();
        pan.setBounds(100, 100, 900, 150);
        pan.setBackground(Color.cyan);
        lab.setBackground(Color.white);
        lab.setFont(tite);
        pan.add(lab);
        con.add(pan);
        Title title = new Title();
        button.addActionListener(title);
        frame1.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
    }
    public static void main(String[] args) throws Exception {
        new App();
    }
    public void Gamescreen() throws LineUnavailableException {
        JFrame frame = new JFrame("FLAPPY BIRD 💕❤️🦜🦜🦜");
        button.setVisible(false);
        frame1.setVisible(false);
        pan.setVisible(false);
        lab.setVisible(false);
        Background background= new Background();
       frame.add(background);  
       frame.setSize(600,600);    
       frame.setVisible(true); 
        frame.add(background); 
        frame.pack();
        background.requestFocus();
       frame.setVisible(true);
       frame.setResizable(false);
        Musico.Run("Samplegame music.wav");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
    }

   public class Title implements ActionListener{
        public void actionPerformed(ActionEvent event){
            try {
                Gamescreen();
            } catch (LineUnavailableException ex) {
            }

        }

    }
}
 
