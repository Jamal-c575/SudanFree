def check_brackets(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    idx = content.find("return Scaffold(")
    if idx == -1:
        return
    
    stack = []
    line_num = content[:idx].count('\n') + 1
    
    for i in range(idx, len(content)):
        c = content[i]
        if c == '\n':
            line_num += 1
        elif c == '(':
            stack.append((c, line_num))
            print(f"Open '(' at {line_num}")
        elif c == ')':
            if not stack:
                print(f"Extra ')' at {line_num}")
            else:
                top = stack.pop()
                print(f"Close ')' at {line_num} matching {top[1]}")
        
check_brackets('lib/views/auth/login_screen.dart')
