import sys
from pathlib import Path

# Add backend directory to path
sys.path.insert(0, str(Path(__file__).resolve().parent))

import uvicorn
from config import HOST, PORT

if __name__ == "__main__":
    print(f"Starting Athletix AI Server at http://{HOST}:{PORT}")
    uvicorn.run("api.main:app", host=HOST, port=PORT, reload=False)
