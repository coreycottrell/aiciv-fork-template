#!/usr/bin/env python3
"""
Hourly BOOP Review - Status check every hour
Sends system status to Telegram for oversight
"""

import json
import os
import re
import time
import subprocess
from datetime import datetime
from pathlib import Path


def get_asv_detailed_status():
    """
    Get detailed ASV trader status by running main.py --status.

    Returns parsed status info including:
    - Process running state
    - Current price and baseline
    - % from baseline
    - Spike status
    - Daily trades
    - Error count
    """
    result = {
        "running": False,
        "pid": None,
        "mode": "unknown",
        "current_price": None,
        "baseline": None,
        "baseline_mode": None,
        "pct_from_baseline": None,
        "in_spike": False,
        "spike_level": 0,
        "daily_trades": 0,
        "max_daily_trades": 20,
        "error_count": 0,
        "max_errors": 5,
        "circuit_breaker_active": False,
        "kill_switch_active": False,
        "position_remaining_pct": None,
        "realized_pnl": None,
        "alerts": []
    }

    try:
        # Check if process running via PID file
        pid_file = Path("/tmp/asv_paper_trading.pid")
        if pid_file.exists():
            pid = pid_file.read_text().strip()
            ps_result = subprocess.run(["ps", "-p", pid], capture_output=True)
            result["running"] = ps_result.returncode == 0
            if result["running"]:
                result["pid"] = pid

        # Get current price from price file
        price_file = Path("/tmp/asv_price.txt")
        if price_file.exists():
            price_content = price_file.read_text().strip()
            # Try to extract price value
            price_match = re.search(r'\$?([\d.]+)', price_content)
            if price_match:
                result["current_price"] = float(price_match.group(1))

        # Run main.py --status to get detailed status
        asv_dir = Path(__file__).parent / "asv_trader"
        if asv_dir.exists():
            status_result = subprocess.run(
                ["python3", "main.py", "--status"],
                cwd=str(asv_dir),
                capture_output=True,
                text=True,
                timeout=30
            )

            if status_result.returncode == 0:
                output = status_result.stdout

                # Parse mode
                mode_match = re.search(r'Mode:\s*(\w+)', output)
                if mode_match:
                    result["mode"] = mode_match.group(1).lower()

                # Parse current price
                price_match = re.search(r'Current:\s*\$([\d.]+)', output)
                if price_match:
                    result["current_price"] = float(price_match.group(1))

                # Parse baseline and mode
                baseline_match = re.search(r'Baseline\s*\(([^)]+)\):\s*\$([\d.]+)', output)
                if baseline_match:
                    result["baseline_mode"] = baseline_match.group(1)
                    result["baseline"] = float(baseline_match.group(2))

                # Parse % from baseline
                pct_match = re.search(r'Vs Baseline:\s*([\+\-]?[\d.]+)%', output)
                if pct_match:
                    result["pct_from_baseline"] = float(pct_match.group(1))

                # Parse spike status
                spike_match = re.search(r'In Spike:\s*(True|False)', output)
                if spike_match:
                    result["in_spike"] = spike_match.group(1) == "True"

                level_match = re.search(r'Spike Level:\s*(\d+)%', output)
                if level_match:
                    result["spike_level"] = int(level_match.group(1))

                # Parse position
                pct_remaining_match = re.search(r'Current:.*\(([\d.]+)%\)', output)
                if pct_remaining_match:
                    result["position_remaining_pct"] = float(pct_remaining_match.group(1))

                pnl_match = re.search(r'Realized P&L:\s*\$([\-\d.]+)', output)
                if pnl_match:
                    result["realized_pnl"] = float(pnl_match.group(1))

                # Parse safety info
                kill_match = re.search(r'Kill Switch:\s*(ACTIVE|OFF)', output)
                if kill_match:
                    result["kill_switch_active"] = kill_match.group(1) == "ACTIVE"

                daily_match = re.search(r'Daily Trades:\s*(\d+)/(\d+)', output)
                if daily_match:
                    result["daily_trades"] = int(daily_match.group(1))
                    result["max_daily_trades"] = int(daily_match.group(2))

                errors_match = re.search(r'Errors:\s*(\d+)/(\d+)', output)
                if errors_match:
                    result["error_count"] = int(errors_match.group(1))
                    result["max_errors"] = int(errors_match.group(2))

                cb_match = re.search(r'Circuit Breaker:\s*(ACTIVE|OK)', output)
                if cb_match:
                    result["circuit_breaker_active"] = cb_match.group(1) == "ACTIVE"

        # Generate alerts based on status
        if not result["running"]:
            result["alerts"].append("PROCESS DOWN")
        if result["kill_switch_active"]:
            result["alerts"].append("KILL SWITCH ACTIVE")
        if result["circuit_breaker_active"]:
            result["alerts"].append("CIRCUIT BREAKER TRIPPED")
        if result["error_count"] >= 3:
            result["alerts"].append(f"HIGH ERRORS: {result['error_count']}")
        if result["in_spike"]:
            result["alerts"].append(f"IN SPIKE: {result['spike_level']}%")

    except subprocess.TimeoutExpired:
        result["alerts"].append("STATUS COMMAND TIMEOUT")
    except Exception as e:
        result["alerts"].append(f"STATUS ERROR: {str(e)[:50]}")

    return result


def get_asv_status():
    """Get ASV trader status (legacy compatibility wrapper)"""
    detailed = get_asv_detailed_status()

    # Build price_info string for legacy format
    if detailed["current_price"] and detailed["baseline"]:
        price_info = f"${detailed['current_price']:.6f} | Base: ${detailed['baseline']:.6f} | {detailed['pct_from_baseline']:+.1f}%"
    elif detailed["current_price"]:
        price_info = f"${detailed['current_price']:.6f}"
    else:
        price_info = "No price data"

    return {
        "running": detailed["running"],
        "pid": detailed["pid"],
        "last_activity": "See detailed status",
        "price_info": price_info,
        "detailed": detailed
    }


def get_system_status():
    """Get overall system status"""
    # Check Telegram bot
    tg_result = subprocess.run(
        ["pgrep", "-f", "telegram_unified.py"],
        capture_output=True
    )
    tg_running = tg_result.returncode == 0

    # Check price ticker
    ticker_result = subprocess.run(
        ["pgrep", "-f", "price_ticker.py"],
        capture_output=True
    )
    ticker_running = ticker_result.returncode == 0

    return {
        "telegram_bot": tg_running,
        "price_ticker": ticker_running,
        "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M")
    }


def send_telegram(message):
    """Send message via telegram_unified.py"""
    script = Path(__file__).parent / "telegram_unified.py"
    subprocess.run(["python3", str(script), "send", message])


def format_asv_section(detailed):
    """Format the ASV PAPER TRADING section for Telegram."""
    # Status indicator with emoji-style markers
    if detailed["running"]:
        status_line = f"Status: RUNNING (PID {detailed['pid']})"
    else:
        status_line = "Status: DOWN"

    # Price section
    if detailed["current_price"]:
        price_line = f"Price: ${detailed['current_price']:.6f}"
    else:
        price_line = "Price: No data"

    # Baseline section
    if detailed["baseline"]:
        baseline_line = f"Baseline ({detailed['baseline_mode']}): ${detailed['baseline']:.6f}"
        if detailed["pct_from_baseline"] is not None:
            pct = detailed["pct_from_baseline"]
            pct_indicator = "+" if pct >= 0 else ""
            baseline_line += f"\nVs Baseline: {pct_indicator}{pct:.1f}%"
    else:
        baseline_line = "Baseline: Not set"

    # Spike section
    if detailed["in_spike"]:
        spike_line = f"Spike: YES at {detailed['spike_level']}%"
    else:
        spike_line = "Spike: No"

    # Trading stats
    trades_line = f"Daily Trades: {detailed['daily_trades']}/{detailed['max_daily_trades']}"
    errors_line = f"Errors: {detailed['error_count']}/{detailed['max_errors']}"

    # Position info
    if detailed["position_remaining_pct"] is not None:
        position_line = f"Position: {detailed['position_remaining_pct']:.1f}% remaining"
    else:
        position_line = "Position: Unknown"

    if detailed["realized_pnl"] is not None:
        pnl_line = f"Realized PnL: ${detailed['realized_pnl']:.2f}"
    else:
        pnl_line = ""

    # Safety status
    safety_parts = []
    if detailed["kill_switch_active"]:
        safety_parts.append("KILL SWITCH ON")
    if detailed["circuit_breaker_active"]:
        safety_parts.append("CIRCUIT BREAKER")
    safety_line = "Safety: " + (", ".join(safety_parts) if safety_parts else "OK")

    # Alerts section
    if detailed["alerts"]:
        alerts_line = "ALERTS: " + " | ".join(detailed["alerts"])
    else:
        alerts_line = ""

    # Build the section
    lines = [
        "--- ASV PAPER TRADING ---",
        status_line,
        price_line,
        baseline_line,
        spike_line,
        trades_line,
        errors_line,
        position_line,
    ]

    if pnl_line:
        lines.append(pnl_line)

    lines.append(safety_line)

    if alerts_line:
        lines.append("")
        lines.append(alerts_line)

    return "\n".join(lines)


def hourly_boop():
    """Run hourly BOOP review"""
    asv = get_asv_status()
    detailed = asv.get("detailed", get_asv_detailed_status())
    sys_status = get_system_status()

    # Build status indicators
    tg_indicator = 'YES' if sys_status['telegram_bot'] else 'NO'
    ticker_indicator = 'YES' if sys_status['price_ticker'] else 'NO'

    # Build the ASV section
    asv_section = format_asv_section(detailed)

    # Check for critical alerts
    has_critical = bool(detailed["alerts"]) and not detailed["running"]

    msg = f"""HOURLY BOOP - {sys_status['timestamp']}

{asv_section}

--- SYSTEM ---
Telegram Bot: {tg_indicator}
Price Ticker: {ticker_indicator}
"""

    # Add critical alert banner if needed
    if has_critical:
        msg = "!!! ATTENTION REQUIRED !!!\n\n" + msg

    send_telegram(msg)
    print(f"[{sys_status['timestamp']}] Hourly BOOP sent")


def main():
    """Run hourly BOOP loop"""
    print("Starting hourly BOOP reviews...")
    while True:
        try:
            hourly_boop()
        except Exception as e:
            print(f"Error in BOOP: {e}")
        # Wait 1 hour
        time.sleep(3600)


if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "--once":
        hourly_boop()
    else:
        main()
