import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;

public class Main {
    public static void main(String[] args) {
        try {
            String spaceToken = System.getenv("SPACE_TOKEN");
            if (spaceToken == null || spaceToken.isEmpty()) {
                spaceToken = "_";
            }

            //通过 args[1] 读取文件
            File file = new File(args[0]);
            String start = args[1].replace(spaceToken, " ");
            String end = args[2].replace(spaceToken, " ");
            String ref = "";
            if (args.length > 3) {
                ref = toString(new File(args[3]));
            }
            String prefix = "";
            if (args.length > 4) {
                prefix = args[4].replace(spaceToken, " ");
            }
            String suffix = "";
            if (args.length > 5) {
                suffix = args[5].replace(spaceToken, " ");
            }
            //逐行读取
            BufferedReader reader = new BufferedReader(new FileReader(file));

            String line;
            boolean isStart = false;
            boolean isOutted = false;
            while ((line = reader.readLine()) != null) {
                if (line.contains(start)) {
                    isStart = true;
                }
                if (isStart && !isOutted) {
                    System.out.println(start);
                    String[] refs = ref.split("\n");
                    for (final String s : refs) {
                        System.out.println(prefix + s + suffix);
                    }
                    isOutted = true;
                }
                if (!isStart) {
                    System.out.println(line);
                }
                if (isStart && line.contains(end)) {
                    isStart = false;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private static String toString(File refFile) throws IOException {
        if (!refFile.exists()) {
            return "";
        }
        BufferedReader reader = new BufferedReader(new FileReader(refFile));
        String line = null;
        StringBuilder sb = new StringBuilder();
        while ((line = reader.readLine()) != null) {
            sb.append(line).append("\n");
        }
        return sb.toString();
    }
}
//javac Main.java && java Main
