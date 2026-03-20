package com.calculator;

import org.apache.catalina.Context;
import org.apache.catalina.startup.Tomcat;

import java.io.*;
import java.net.URL;
import java.nio.file.*;
import java.util.Enumeration;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;

/**
 * Main — boots embedded Tomcat with JSP support from a fat JAR.
 *
 * JSP files live inside the JAR under  webapp/
 * At startup they are extracted to a temp dir so Jasper can compile them.
 *
 * Run:  java -jar target/calculator.jar
 * Open: http://localhost:8080/
 */
public class Main {

    private static final int PORT = Integer.parseInt(
            System.getProperty("port", "8080"));

    public static void main(String[] args) throws Exception {

        String webappPath = resolveWebappDir();
        System.out.println("[main] Webapp dir: " + webappPath);

        Tomcat tomcat = new Tomcat();
        tomcat.setPort(PORT);
        tomcat.getConnector();

        File workDir = Files.createTempDirectory("tomcat-work").toFile();
        tomcat.setBaseDir(workDir.getAbsolutePath());

        Context ctx = tomcat.addWebapp("", webappPath);
        ctx.setReloadable(false);

        System.out.println("==========================================");
        System.out.printf("  Java Calculator  —  port %d%n", PORT);
        System.out.printf("  Open: http://localhost:%d/%n", PORT);
        System.out.println("==========================================");

        tomcat.start();
        tomcat.getServer().await();
    }

    private static String resolveWebappDir() throws Exception {
        // Dev mode: src/main/webapp exists on disk
        File devWebapp = new File("src/main/webapp");
        if (devWebapp.exists()) return devWebapp.getAbsolutePath();

        // JAR mode: extract webapp/ entries from inside the fat JAR
        URL jarUrl = Main.class.getProtectionDomain()
                               .getCodeSource().getLocation();
        File jarFile  = new File(jarUrl.toURI());
        File tempDir  = Files.createTempDirectory("calc-webapp").toFile();
        extractFromJar(jarFile, "webapp/", tempDir);
        return tempDir.getAbsolutePath();
    }

    private static void extractFromJar(File jar, String prefix, File destDir)
            throws IOException {
        try (JarFile jf = new JarFile(jar)) {
            Enumeration<JarEntry> entries = jf.entries();
            while (entries.hasMoreElements()) {
                JarEntry entry = entries.nextElement();
                String name = entry.getName();
                if (!name.startsWith(prefix)) continue;
                String relative = name.substring(prefix.length());
                if (relative.isEmpty()) continue;
                File dest = new File(destDir, relative);
                if (entry.isDirectory()) { dest.mkdirs(); continue; }
                dest.getParentFile().mkdirs();
                try (InputStream in  = jf.getInputStream(entry);
                     OutputStream out = new FileOutputStream(dest)) {
                    in.transferTo(out);
                }
            }
        }
    }
}
