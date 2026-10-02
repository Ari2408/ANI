import re

with open('/home/dinakar3108/Downloads/PR1/lib/services/i18n_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace any sequence of 2 or more backslashes followed by optional apostrophe
# e.g. \\\\\\\\\\\\\\\' -> \'
cleaned_content = re.sub(r'\\+\'', r"\\'", content)
cleaned_content = re.sub(r'\\\\+', r"", cleaned_content)

with open('/home/dinakar3108/Downloads/PR1/lib/services/i18n_service.dart', 'w', encoding='utf-8') as f:
    f.write(cleaned_content)

print("Scrubbed all redundant backslashes from i18n_service.dart.")
