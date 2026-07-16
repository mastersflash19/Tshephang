
import java.io.File;
import java.io.IOException;
import javax.sound.sampled.AudioInputStream;
import javax.sound.sampled.AudioSystem;
import javax.sound.sampled.Clip;
import javax.sound.sampled.LineUnavailableException;
import javax.sound.sampled.UnsupportedAudioFileException;
public class Musico {
    public static void Run(String path) throws LineUnavailableException{
        try {
            AudioInputStream input=AudioSystem.getAudioInputStream(new File(path));
            Clip clip=AudioSystem.getClip();
            clip.open(input);
            clip.loop(5);

        } catch (UnsupportedAudioFileException e) {
            e.printStackTrace();
        }catch (IOException e) {
            e.printStackTrace();
        }
        catch (LineUnavailableException e) {
            e.printStackTrace();
        }
}
}
