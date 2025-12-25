#!/usr/bin/env python3

import os
import subprocess
import json
import sys
from pathlib import Path

def run_command(cmd, description, allow_exit_1=False):
    """Run a command and handle errors gracefully"""
    print(f"🔍 {description}...")
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, cwd=os.getcwd())
        if result.returncode == 0:
            print(f"✅ {description} completed")
            return True
        elif result.returncode == 1 and allow_exit_1:
            print(f"✅ {description} completed (found security issues)")
            return True
        else:
            print(f"❌ {description} failed with exit code {result.returncode}")
            if result.stderr:
                print(f"Error: {result.stderr}")
            return False
    except Exception as e:
        print(f"❌ Error running {description}: {e}")
        return False

def main():
    print("🔍 Starting comprehensive security scan...")
    
    # Create reports directory
    reports_dir = Path("reports")
    reports_dir.mkdir(exist_ok=True)
    os.chdir(reports_dir)
    
    # Clean previous reports
    for file in reports_dir.glob("*"):
        if file.is_file():
            file.unlink()
    
    success_count = 0
    total_tools = 3
    
    # Run Checkov
    print("\n📋 Running Checkov scan...")
    checkov_commands = [
        ("checkov -d ../infrastructure-catalog -d ../infrastructure-live --framework terraform --output sarif --output-file-path checkov-results.sarif --quiet", "Checkov SARIF", True),
        ("checkov -d ../infrastructure-catalog -d ../infrastructure-live --framework terraform --output json --output-file-path checkov-results.json --quiet", "Checkov JSON", True),
        ("checkov -d ../infrastructure-catalog -d ../infrastructure-live --framework terraform --output cli > checkov-cli-output.txt", "Checkov CLI", True)
    ]
    
    checkov_success = 0
    for cmd, desc, allow_exit_1 in checkov_commands:
        if run_command(cmd, desc, allow_exit_1):
            checkov_success += 1
    
    if checkov_success > 0:
        success_count += 1
        print("✅ Checkov completed")
    
    # Run Trivy
    print("\n🛡️  Running Trivy scan...")
    trivy_commands = [
        ("trivy config .. --format sarif --output trivy-results.sarif --quiet", "Trivy SARIF"),
        ("trivy config .. --format json --output trivy-results.json --quiet", "Trivy JSON"),
        ("trivy config .. --format table --output trivy-table-output.txt --quiet", "Trivy Table")
    ]
    
    trivy_success = 0
    for cmd, desc in trivy_commands:
        if run_command(cmd, desc, False):
            trivy_success += 1
    
    if trivy_success > 0:
        success_count += 1
        print("✅ Trivy completed")
    
    # Run Semgrep
    print("\n🔒 Running Semgrep scan...")
    semgrep_commands = [
        ("semgrep --config=p/security-audit --config=p/secrets ../infrastructure-catalog --sarif --output semgrep-results.sarif --quiet", "Semgrep SARIF"),
        ("semgrep --config=p/security-audit --config=p/secrets ../infrastructure-catalog --json --output semgrep-results.json --quiet", "Semgrep JSON")
    ]
    
    semgrep_success = 0
    for cmd, desc in semgrep_commands:
        if run_command(cmd, desc, False):
            semgrep_success += 1
    
    if semgrep_success > 0:
        success_count += 1
        print("✅ Semgrep completed")
    
    # Generate summary
    print("\n📊 Generating summary report...")
    
    def count_findings(file_path, file_type):
        try:
            if not Path(file_path).exists():
                return "N/A"
            
            if file_type == "sarif":
                with open(file_path, 'r') as f:
                    data = json.load(f)
                    return len(data.get('runs', [{}])[0].get('results', []))
            elif file_type == "json" and "semgrep" in file_path:
                with open(file_path, 'r') as f:
                    data = json.load(f)
                    return len(data.get('results', []))
            elif file_type == "json" and "checkov" in file_path:
                with open(file_path, 'r') as f:
                    data = json.load(f)
                    return len(data.get('results', {}).get('failed_checks', []))
            else:
                return "N/A"
        except Exception as e:
            return f"Error: {e}"
    
    # Create summary
    summary = f"""Security Scan Summary - {subprocess.run('date', shell=True, capture_output=True, text=True).stdout.strip()}
================================

Tools Status:
- Checkov: {'✅ Success' if checkov_success > 0 else '❌ Failed'}
- Trivy: {'✅ Success' if trivy_success > 0 else '❌ Failed'}  
- Semgrep: {'✅ Success' if semgrep_success > 0 else '❌ Failed'}

Findings Count:
- Checkov: {count_findings('checkov-results.sarif', 'sarif')} findings
- Trivy: {count_findings('trivy-results.sarif', 'sarif')} findings
- Semgrep: {count_findings('semgrep-results.json', 'json')} findings

Generated Files:
"""
    
    # List generated files
    files = list(Path('.').glob('*'))
    if files:
        for file in sorted(files):
            if file.is_file():
                summary += f"- {file.name}\n"
    else:
        summary += "- No files generated\n"
    
    summary += "\nUsage:\n- Open SARIF files in VS Code: code *.sarif\n- View JSON files for programmatic analysis\n- Read CLI/table files for human-readable output\n"
    
    with open('security-summary.txt', 'w') as f:
        f.write(summary)
    
    print("✅ Security scan complete!")
    print(f"📁 Reports saved in: {Path.cwd()}")
    print(f"🎯 {success_count}/{total_tools} tools completed successfully")
    
    # List all generated files
    files = list(Path('.').glob('*'))
    if files:
        print("\n📄 Generated files:")
        for file in sorted(files):
            if file.is_file():
                size = file.stat().st_size
                print(f"  - {file.name} ({size} bytes)")
    
    print("\n🔍 View findings: code *.sarif")

if __name__ == "__main__":
    main()
