import io
try:
    with io.open('crash.txt', 'r', encoding='utf-16le', errors='ignore') as f:
        lines = f.readlines()
        
    for i in range(len(lines)-1, -1, -1):
        if 'FATAL EXCEPTION' in lines[i]:
            start = max(0, i-2)
            for j in range(start, start+45):
                if j < len(lines):
                    print(lines[j].strip())
            break
except Exception as e:
    print(e)
