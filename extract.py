import sys, re
with open('build_log_fail4.txt', 'r', encoding='utf-8') as f:
    text = f.read()

matches = re.findall(r'.{0,100}\.swift:\d+:\d+:.{0,100}', text)
for m in matches[-20:]:
    print(m)
