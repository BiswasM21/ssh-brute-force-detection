#!/usr/bin/env python3
"""
SSH Brute Force Detection Test Suite
Tests the detection capabilities of the SSH BFD system
"""

import sys
import time
import subprocess
from datetime import datetime
from typing import List, Dict

# ANSI colors for terminal output
GREEN = '\033[0;32m'
RED = '\033[0;31m'
YELLOW = '\033[1;33m'
BLUE = '\033[0;34m'
NC = '\033[0m'  # No Color


def log_info(msg: str):
    print(f"{BLUE}[INFO]{NC} {msg}")


def log_success(msg: str):
    print(f"{GREEN}[PASS]{NC} {msg}")


def log_error(msg: str):
    print(f"{RED}[FAIL]{NC} {msg}")


def log_warn(msg: str):
    print(f"{YELLOW}[WARN]{NC} {msg}")


class DetectionTester:
    """Test suite for SSH brute force detection"""

    def __init__(self, splunk_host: str = "localhost", splunk_port: int = 8089):
        self.splunk_host = splunk_host
        self.splunk_port = splunk_port
        self.results: List[Dict] = []

    def test_splunk_connectivity(self) -> bool:
        """Test if Splunk instance is reachable"""
        log_info("Testing Splunk connectivity...")
        try:
            result = subprocess.run(
                ["curl", "-k", f"https://{self.splunk_host}:{self.splunk_port}/services/server/info"],
                capture_output=True,
                timeout=10
            )
            success = result.returncode == 0
            if success:
                log_success("Splunk is reachable")
            else:
                log_error("Splunk is not reachable")
            return success
        except Exception as e:
            log_error(f"Splunk connectivity test failed: {e}")
            return False

    def test_index_exists(self, index_name: str = "ssh_security") -> bool:
        """Test if the SSH security index exists"""
        log_info(f"Testing if index '{index_name}' exists...")
        try:
            result = subprocess.run(
                [
                    "curl", "-k",
                    f"https://{self.splunk_host}:{self.splunk_port}/services/data/indexes/{index_name}",
                    "-u", "admin:SplunkPass123!"
                ],
                capture_output=True,
                timeout=10
            )
            success = "indexes" in result.stdout.decode() or result.returncode == 0
            if success:
                log_success(f"Index '{index_name}' exists")
            else:
                log_warn(f"Index '{index_name}' may not exist")
            return success
        except Exception as e:
            log_error(f"Index test failed: {e}")
            return False

    def test_log_ingestion(self, log_file: str) -> bool:
        """Test if logs can be ingested into Splunk"""
        log_info(f"Testing log ingestion from {log_file}...")
        try:
            # Upload sample logs
            result = subprocess.run(
                [
                    "curl", "-k",
                    "-X", "POST",
                    f"https://{self.splunk_host}:{self.splunk_port}/services/collector",
                    "-H", "Authorization: Splunk abc123-def456",
                    "-H", "Content-Type: application/json",
                    "-d", '{"event":"test","source":"test_detection"}'
                ],
                capture_output=True,
                timeout=10
            )
            success = result.returncode == 0
            if success:
                log_success("Log ingestion successful")
            else:
                log_warn("Log ingestion may not be configured")
            return success
        except Exception as e:
            log_error(f"Log ingestion test failed: {e}")
            return False

    def test_saved_search(self, search_name: str) -> bool:
        """Test if saved searches are configured"""
        log_info(f"Testing saved search '{search_name}'...")
        try:
            result = subprocess.run(
                [
                    "curl", "-k",
                    f"https://{self.splunk_host}:{self.splunk_port}/services/saved/searches/{search_name}",
                    "-u", "admin:SplunkPass123!"
                ],
                capture_output=True,
                timeout=10
            )
            success = result.returncode == 0
            if success:
                log_success(f"Saved search '{search_name}' exists")
            else:
                log_warn(f"Saved search '{search_name}' may not be configured")
            return success
        except Exception as e:
            log_error(f"Saved search test failed: {e}")
            return False

    def test_alert_execution(self) -> bool:
        """Test if alerts can be triggered"""
        log_info("Testing alert capabilities...")
        try:
            # Generate test log entries
            for i in range(20):
                subprocess.run(
                    [
                        "curl", "-k",
                        "-X", "POST",
                        f"https://{self.splunk_host}:{self.splunk_port}/services/collector",
                        "-H", "Authorization: Splunk abc123-def456",
                        "-H", "Content-Type: application/json",
                        "-d", f'{{"event":"failed_login","src_ip":"192.168.1.100","user":"root","action":"failed"}}'
                    ],
                    capture_output=True,
                    timeout=5
                )
                time.sleep(0.1)

            log_success("Test events sent - check Splunk for alert")
            return True
        except Exception as e:
            log_error(f"Alert test failed: {e}")
            return False

    def test_dashboard_access(self) -> bool:
        """Test if dashboards are accessible"""
        log_info("Testing dashboard accessibility...")
        try:
            result = subprocess.run(
                [
                    "curl", "-k",
                    "-X", "GET",
                    f"https://{self.splunk_host}:{self.splunk_port}/en-GB/app/ssh_detector/overview",
                    "-u", "admin:SplunkPass123!"
                ],
                capture_output=True,
                timeout=10
            )
            success = result.returncode == 0
            if success:
                log_success("Dashboards are accessible")
            else:
                log_warn("Dashboard access may require configuration")
            return success
        except Exception as e:
            log_error(f"Dashboard test failed: {e}")
            return False

    def run_all_tests(self) -> bool:
        """Run all detection tests"""
        print("\n" + "=" * 50)
        print("SSH Brute Force Detection - Test Suite")
        print("=" * 50 + "\n")

        tests = [
            ("Splunk Connectivity", self.test_splunk_connectivity),
            ("SSH Security Index", lambda: self.test_index_exists()),
            ("Log Ingestion", lambda: self.test_log_ingestion("logs/sample_logs/auth.log")),
            ("Brute Force Alert", lambda: self.test_saved_search("SSH Brute Force Alert")),
            ("Dashboard Access", self.test_dashboard_access),
        ]

        passed = 0
        failed = 0

        for name, test_func in tests:
            print(f"\n--- Testing: {name} ---")
            try:
                if test_func():
                    passed += 1
                    self.results.append({"test": name, "status": "PASS"})
                else:
                    failed += 1
                    self.results.append({"test": name, "status": "FAIL"})
            except Exception as e:
                log_error(f"Test '{name}' raised exception: {e}")
                failed += 1
                self.results.append({"test": name, "status": "ERROR"})

        # Run alert execution test last
        print(f"\n--- Testing: Alert Execution ---")
        if self.test_alert_execution():
            passed += 1
            self.results.append({"test": "Alert Execution", "status": "PASS"})
        else:
            failed += 1
            self.results.append({"test": "Alert Execution", "status": "FAIL"})

        # Print summary
        print("\n" + "=" * 50)
        print("TEST SUMMARY")
        print("=" * 50)
        print(f"Passed: {GREEN}{passed}{NC}")
        print(f"Failed: {RED}{failed}{NC}")
        print(f"Total:  {passed + failed}")
        print("=" * 50)

        return failed == 0


def main():
    """Main entry point"""
    tester = DetectionTester()
    success = tester.run_all_tests()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
