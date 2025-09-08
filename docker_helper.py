import subprocess
import sys

def run(cmd):
    print(f"Running: {cmd}")
    subprocess.run(cmd, shell=True, check=True)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python docker_helper.py [up|down|restart|ps|prune|prod]")
        sys.exit(1)
    action = sys.argv[1]
    if action == "up":
        run("docker compose -f docker-compose.yml -f docker-compose.dev.yml up")
    elif action == "down":
        run("docker compose down")
    elif action == "restart":
        run("docker compose down")
        run("docker compose -f docker-compose.yml -f docker-compose.dev.yml up")
    elif action == "ps":
        run("docker ps -a")
    elif action == "prune":
        # Remove containers, images, networks, and volumes created by this app's compose files
        run("docker compose -f docker-compose.yml -f docker-compose.dev.yml down -v --rmi all")
    elif action == "prod":
        # Run production deployment using production compose file
        run("docker compose -f docker-compose.yml -f docker-compose.prod.yml up --build -d")
    else:
        print("Unknown command")