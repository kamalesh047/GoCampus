import os
import subprocess

env = os.environ.copy()
env["JAVA_HOME"] = "c:/Users/KAMALESH/.gemini/antigravity/scratch/go_campus/build_tools/jdk17/jdk-17.0.12+7"
env["GRADLE_OPTS"] = "-Xmx2048m"

try:
    with open('build_err.log', 'w', encoding='utf-8') as f:
        # Launching with custom env containing the JDK override
        out = subprocess.check_output('flutter build apk --release', shell=True, text=True, stderr=subprocess.STDOUT, env=env)
        f.write(out)
except subprocess.CalledProcessError as e:
    with open('build_err.log', 'w', encoding='utf-8') as f:
        f.write(e.output)
