import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.NoSuchAlgorithmException;
import java.util.Base64;

public class Main {
    public static void main(String[] args) {
        String RSA_PRIVATE_KEY_PEM;
        String RSA_PUBLIC_KEY_PEM;
        try {
            final KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance("RSA");
            keyPairGenerator.initialize(1024);
            final KeyPair keyPair = keyPairGenerator.generateKeyPair();

            RSA_PRIVATE_KEY_PEM = "-----BEGIN PRIVATE KEY-----\n" +
                    Base64.getMimeEncoder().encodeToString(keyPair.getPrivate().getEncoded()) +
                    "\n" + "-----END PRIVATE KEY-----";
            RSA_PUBLIC_KEY_PEM = "-----BEGIN PUBLIC KEY-----\n" +
                    Base64.getMimeEncoder().encodeToString(keyPair.getPublic().getEncoded()) +
                    "\n" + "-----END PUBLIC KEY-----";
            System.out.println("Public: \n" + RSA_PUBLIC_KEY_PEM);
            System.out.println("Private: \n" + RSA_PRIVATE_KEY_PEM);
        } catch (NoSuchAlgorithmException e) {
            throw new AssertionError(e);
        }
    }
}
//javac Main.java && java Main