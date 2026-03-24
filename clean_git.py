import re
import sys

def clean_git_markers(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Simple strategy: Keep HEAD (our changes) and remove markers/theirs
    # Pattern: <<<<<<< HEAD\n(.*?)\n=======\n(.*?)\n>>>>>>> [a-f0-8]+
    cleaned = re.sub(r'<<<<<<< HEAD\n(.*?)\n=======\n(.*?)\n>>>>>>> [a-f0-9]+', r'\1', content, flags=re.DOTALL)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(cleaned)

if __name__ == "__main__":
    clean_git_markers(sys.argv[1])
