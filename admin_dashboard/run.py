import subprocess
import os
import sys

def main():
    # USLS Admin Dashboard Runner
    print("--- ParkAlisto USLS Admin Dashboard ---")
    
    # Change directory to admin_dashboard if not already there
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)
    
    # Check for node_modules
    if not os.path.exists('node_modules'):
        print("Installing dependencies...")
        subprocess.run(['npm', 'install'], check=True)
    
    print("Starting development server...")
    try:
        subprocess.run(['npm', 'run', 'dev'])
    except KeyboardInterrupt:
        print("\nStopping admin dashboard...")
        sys.exit(0)

if __name__ == "__main__":
    main()
