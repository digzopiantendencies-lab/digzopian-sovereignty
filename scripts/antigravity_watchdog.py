import logging
import time
import os
import sys
from vortex_scraper import VortexScraper
from pattern_analyst import PatternAnalyst
from sandbox_sim import SandboxSim

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - [%(levelname)s] - %(message)s'
)
logger = logging.getLogger("HiveOrchestrator")

def main():
    logger.info("Starting Antigravity Watchdog Orchestrator")
    
    # Check for external configuration
    discord_webhook = os.getenv("DISCORD_WEBHOOK")
    if discord_webhook:
        logger.info("Discord Webhook endpoint connected.")
    else:
        logger.warning("No Discord Webhook configured. Alerts will only be local.")
        
    interrupt_code = os.getenv("INTERRUPT_CODE")
    if interrupt_code:
        logger.info(f"Interrupt Override Code loaded: {interrupt_code}")

    logger.info("Initializing Swarm Nodes...")
    scraper = VortexScraper()
    analyst = PatternAnalyst()
    sandbox = SandboxSim()

    cycle = 1
    # Run 3 cycles for demonstration, then exit 
    # (In a real deployment, this would be an infinite loop with longer sleep times)
    while cycle <= 3:
        logger.info(f"--- Starting Swarm Cycle {cycle} ---")
        try:
            # Stage 1: Reconnaissance
            anomalies = scraper.run_recon_cycle()
            
            # Stage 2: Analysis
            analysis = analyst.analyze_anomalies(anomalies)
            
            # Stage 3: Simulation / Bastion Defense
            sandbox.simulate_threats(analysis)
            
            logger.info(f"--- Swarm Cycle {cycle} Complete. ---")
        except Exception as e:
            logger.error(f"Critical error in cycle {cycle}: {e}")
        
        if cycle < 3:
            logger.info("Sleeping before next cycle...")
            time.sleep(5)
            
        cycle += 1
        
    logger.info("Watchdog execution completed successfully.")
    sys.exit(0)

if __name__ == "__main__":
    main()
