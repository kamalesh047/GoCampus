import subprocess
try:
    with open('doctor.log', 'w', encoding='utf-8') as f:
        out = subprocess.check_output('flutter doctor -v', shell=True, text=True, stderr=subprocess.STDOUT)
        f.write(out)
except subprocess.CalledProcessError as e:
    with open('doctor.log', 'w', encoding='utf-8') as f:
        f.write(e.output)
