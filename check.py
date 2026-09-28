import sys

with open('ViewModels/ChatViewModel.swift', 'r', encoding='utf-8') as f:
    lines = f.readlines()

count = 0
for i, line in enumerate(lines):
    open_b = line.count('{')
    close_b = line.count('}')
    count += open_b - close_b
    if count < 0:
        print(f"Brace count went negative at line {i+1}: {line.strip()}")
        break

print(f"Final brace count: {count}")