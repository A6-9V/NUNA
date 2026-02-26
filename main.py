import sys
import os
# Add bridge to path so we can run from root
sys.path.append(os.path.join(os.path.dirname(__file__), 'bridge'))
from bridge.main import main

if __name__ == "__main__":
    main()
