import sys

with open('Views/Messages/ChatView.swift', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('AÁudio', 'Audio')
content = content.replace('Text("udio")', 'Text("Áudio")')
content = content.replace('Text("ÁÁudio")', 'Text("Áudio")')

with open('Views/Messages/ChatView.swift', 'w', encoding='utf-8') as f:
    f.write(content)
