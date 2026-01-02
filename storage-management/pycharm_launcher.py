#!/usr/bin/env python3
"""
PyCharm Quick Launcher for DC Sync Management
Team A6_9V - 3 Members
Created: November 7, 2025
"""

import os
import sys
import subprocess
import json
from pathlib import Path

class DCProjectLauncher:
    def __init__(self):
        self.project_root = Path(__file__).parent
        self.config = self.load_project_config()
        
    def load_project_config(self):
        """Load project configuration"""
        config_file = self.project_root / "project.json"
        if config_file.exists():
            with open(config_file, 'r') as f:
                return json.load(f)
        return {}
    
    def show_welcome(self):
        """Display welcome message for PyCharm users"""
        print("🎯 DC SYNC MANAGEMENT - PYCHARM PROJECT")
        print("=" * 50)
        print(f"Team: {self.config.get('team', {}).get('name', 'A6_9V')}")
        print(f"Members: {self.config.get('team', {}).get('members', 3)}")
        print(f"Version: {self.config.get('version', '1.0.0')}")
        print()
        
    def show_menu(self):
        """Display main menu"""
        print("📋 AVAILABLE ACTIONS:")
        print()
        print("🧪 SANDBOX TESTING:")
        print("  1. Run Sandbox Demo")
        print("  2. Open Sandbox Notebook")
        print("  3. Launch Jupyter Server")
        print()
        print("🚀 PRODUCTION:")
        print("  4. Open Production Notebook")
        print("  5. Run DC Transfer Helper")
        print("  6. View Documentation")
        print()
        print("🔧 UTILITIES:")
        print("  7. Check Project Status")
        print("  8. Install Dependencies")
        print("  9. Open in PyCharm")
        print("  0. Exit")
        print()
        
    def run_sandbox_demo(self):
        """Run sandbox demonstration"""
        print("🎭 Starting Sandbox Demo...")
        sandbox_script = self.project_root / "sandbox" / "DC-Sync-Sandbox.ps1"
        
        try:
            result = subprocess.run([
                'powershell.exe', 
                '-ExecutionPolicy', 'Bypass',
                '-File', str(sandbox_script),
                '-Mode', 'Demo',
                '-ShowCommands'
            ], cwd=self.project_root, check=True)
            print("✅ Sandbox demo completed!")
        except subprocess.CalledProcessError as e:
            print(f"❌ Sandbox demo failed: {e}")
    
    def open_sandbox_notebook(self):
        """Open sandbox testing notebook"""
        notebook = self.project_root / "sandbox" / "DC-Sandbox-Testing.ipynb"
        if notebook.exists():
            print(f"📓 Opening notebook: {notebook}")
            try:
                subprocess.run(['jupyter', 'notebook', str(notebook)], 
                             cwd=self.project_root)
            except FileNotFoundError:
                print("❌ Jupyter not found. Install with: pip install jupyter")
        else:
            print("❌ Sandbox notebook not found")
    
    def launch_jupyter(self):
        """Launch Jupyter server"""
        print("🚀 Starting Jupyter Server on port 8888...")
        try:
            subprocess.run(['jupyter', 'notebook', '--port=8888'], 
                         cwd=self.project_root)
        except FileNotFoundError:
            print("❌ Jupyter not found. Install with: pip install jupyter")
    
    def open_production_notebook(self):
        """Open production guide notebook"""
        notebook = self.project_root / "production" / "DC-Sync-Jupyter-Guide.ipynb"
        if notebook.exists():
            print(f"📓 Opening production guide: {notebook}")
            try:
                subprocess.run(['jupyter', 'notebook', str(notebook)], 
                             cwd=self.project_root)
            except FileNotFoundError:
                print("❌ Jupyter not found. Install with: pip install jupyter")
        else:
            print("❌ Production notebook not found")
    
    def run_transfer_helper(self):
        """Run DC transfer helper"""
        script = self.project_root / "production" / "Transfer-Helper.ps1"
        if script.exists():
            print("🔄 Running Transfer Helper...")
            try:
                subprocess.run([
                    'powershell.exe',
                    '-ExecutionPolicy', 'Bypass', 
                    '-File', str(script),
                    '-Help'
                ], cwd=self.project_root)
            except subprocess.CalledProcessError as e:
                print(f"❌ Transfer helper failed: {e}")
        else:
            print("❌ Transfer helper script not found")
    
    def view_documentation(self):
        """View project documentation"""
        docs = [
            ("PyCharm Setup", "PYCHARM-SETUP.md"),
            ("Quick Start", "QUICK-START.md"), 
            ("DC Sync Guide", "production/DC-Sync-Guide.md"),
            ("Transfer Guide", "production/DC-Transfer-Guide.md"),
            ("Final Report", "FINAL-REPORT.md")
        ]
        
        print("📚 Available Documentation:")
        for i, (title, file) in enumerate(docs, 1):
            doc_path = self.project_root / file
            status = "✅" if doc_path.exists() else "❌"
            print(f"  {i}. {status} {title}")
    
    def check_status(self):
        """Check project status"""
        print("📊 PROJECT STATUS:")
        print()
        
        # Check directories
        dirs = ["sandbox", "production", "storage-tools"]
        for dir_name in dirs:
            dir_path = self.project_root / dir_name
            count = len(list(dir_path.glob("*"))) if dir_path.exists() else 0
            status = "✅" if dir_path.exists() else "❌"
            print(f"  {status} {dir_name}/ ({count} files)")
        
        # Check key files
        key_files = [
            "sandbox/DC-Sync-Sandbox.ps1",
            "production/DC-Sync.ps1", 
            ".gitignore",
            ".credentials",
            "project.json"
        ]
        
        print("\n📁 Key Files:")
        for file in key_files:
            file_path = self.project_root / file
            status = "✅" if file_path.exists() else "❌"
            size = f"({file_path.stat().st_size} bytes)" if file_path.exists() else ""
            print(f"  {status} {file} {size}")
    
    def install_dependencies(self):
        """Install required Python packages"""
        packages = ["jupyter", "notebook", "jupyterlab", "ipython"]
        
        print("📦 Installing Python dependencies...")
        for package in packages:
            print(f"Installing {package}...")
            try:
                subprocess.run([sys.executable, '-m', 'pip', 'install', package], 
                             check=True)
                print(f"✅ {package} installed")
            except subprocess.CalledProcessError:
                print(f"❌ Failed to install {package}")
    
    def open_pycharm(self):
        """Attempt to open project in PyCharm"""
        print("🔧 Attempting to open in PyCharm...")
        
        # Common PyCharm installation paths
        pycharm_paths = [
            r"C:\Program Files\JetBrains\PyCharm Community Edition*\bin\pycharm64.exe",
            r"C:\Program Files\JetBrains\PyCharm Professional*\bin\pycharm64.exe",
            r"C:\Users\*\AppData\Local\JetBrains\Toolbox\apps\PyCharm*\bin\pycharm64.exe"
        ]
        
        project_path = str(self.project_root)
        
        # Try to find and launch PyCharm
        try:
            import glob
            for pattern in pycharm_paths:
                matches = glob.glob(pattern)
                if matches:
                    pycharm_exe = matches[0]
                    subprocess.Popen([pycharm_exe, project_path])
                    print(f"✅ Opened project in PyCharm: {project_path}")
                    return
            
            print("❌ PyCharm not found. Please open manually:")
            print(f"   File -> Open -> {project_path}")
            
        except Exception as e:
            print(f"❌ Error opening PyCharm: {e}")
    
    def run(self):
        """Main application loop"""
        self.show_welcome()
        
        while True:
            self.show_menu()
            choice = input("Select an option (0-9): ").strip()
            
            if choice == '1':
                self.run_sandbox_demo()
            elif choice == '2':
                self.open_sandbox_notebook()
            elif choice == '3':
                self.launch_jupyter()
            elif choice == '4':
                self.open_production_notebook()
            elif choice == '5':
                self.run_transfer_helper()
            elif choice == '6':
                self.view_documentation()
            elif choice == '7':
                self.check_status()
            elif choice == '8':
                self.install_dependencies()
            elif choice == '9':
                self.open_pycharm()
            elif choice == '0':
                print("👋 Goodbye! Happy coding with PyCharm!")
                break
            else:
                print("❌ Invalid choice. Please try again.")
            
            input("\nPress Enter to continue...")
            print("\n" + "="*50)

if __name__ == "__main__":
    launcher = DCProjectLauncher()
    launcher.run()