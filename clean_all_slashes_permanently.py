import re

with open('/home/dinakar3108/Downloads/PR1/lib/services/i18n_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace all occurrences of 2 or more backslashes followed by ' or alone
# e.g. Today\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\'s -> Today\'s
content = re.sub(r"\\\\+'", r"\\'", content)
content = re.sub(r"\\\\+", r"", content)

# Check specifically for today's keys and format them cleanly
content = content.replace("Today\\'s", "Today's")
content = content.replace("today\\'s", "today's")

# Use double quotes for any value containing single quotes so no backslashes are needed at all!
def clean_line(line):
    m = re.match(r"^(\s*'([a-zA-Z0-9_]+)':\s*)'(.*)'(\s*,?\s*)$", line)
    if m:
        prefix = m.group(1)
        key = m.group(2)
        val = m.group(3)
        suffix = m.group(4)
        
        # Clean any backslashes before quotes
        val_clean = val.replace("\\'", "'").replace("\\\\", "")
        
        # If val contains single quotes, wrap in double quotes
        if "'" in val_clean and '"' not in val_clean:
            return f'      \'{key}\': "{val_clean}"{suffix}'
        else:
            return f'      \'{key}\': \'{val_clean}\'{suffix}'
    return line

lines = content.split('\n')
new_lines = [clean_line(line) for line in lines]

final_content = '\n'.join(new_lines)

with open('/home/dinakar3108/Downloads/PR1/lib/services/i18n_service.dart', 'w', encoding='utf-8') as f:
    f.write(final_content)

print("Permanently cleaned all slashes from i18n_service.dart.")
