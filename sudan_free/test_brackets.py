def check_brackets(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    idx = content.find("return Scaffold(")
    if idx == -1:
        return
    
    # Simple stack
    stack = []
    line_num = content[:idx].count('\n') + 1
    
    for i in range(idx, len(content)):
        c = content[i]
        if c == '\n':
            line_num += 1
        elif c == '(':
            stack.append((c, line_num))
        elif c == ')':
            if not stack:
                print(f"Extra closing bracket at line {line_num}")
            else:
                stack.pop()
        elif c == '{':
            stack.append((c, line_num))
        elif c == '}':
            if stack and stack[-1][0] == '{':
                stack.pop()
            else:
                if not stack:
                    print(f"Extra closing brace at line {line_num}")
                else:
                    print(f"Mismatch at line {line_num}. Expected {stack[-1][0]}, got }}")
        
        if c == ';' and not stack:
            print(f"Semicolon reached with empty stack at line {line_num}")
            break

check_brackets('lib/views/auth/login_screen.dart')
