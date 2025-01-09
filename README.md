# NinjaOne Agent in Docker for Debian

This project enables running the NinjaOne monitoring agent on FreeBSD systems using Docker containerization. Since NinjaOne doesn't provide native FreeBSD support, we use an Ubuntu container to bridge this compatibility gap.

## Technical Overview

### Core Components and Their Interactions

1. **Base System (Debuan Host)**
   - Runs the Docker environment
   - Provides system resources and metrics
   - Hosts the container runtime

2. **Docker Container (Ubuntu 22.04)**
   - Provides Linux compatibility layer
   - Runs systemd for service management
   - Hosts the NinjaOne agent

### Working Configuration (Last Updated: 2024-12-18)

#### 1. Container Setup
- Uses Ubuntu 22.04 as the base image
- Implements systemd initialization with minimal configuration
- Uses volatile journald storage to prevent persistence issues
- Includes service unmasking and auto-start configuration

#### 2. Key Features
- Host network mode for proper network monitoring
- Privileged mode with specific capabilities
- Host filesystem access for monitoring
- Tmpfs mounts for runtime directories
- Systemd journal configured for container use
- Automatic service unmasking and enabling

#### 3. Critical Configurations

##### Docker Compose Volumes
```yaml
volumes:
  - /sys/fs/cgroup:/sys/fs/cgroup:rw
  - /proc:/host/proc:ro
  - /:/host:ro
  - /var/log:/var/log:ro
  - /var/log/pve:/var/log/pve:ro
tmpfs:
  - /run
  - /run/lock
  - /tmp
  - /var/run
  - /var/log/journal
```

##### Journald Configuration
```ini
[Journal]
Storage=volatile
RuntimeMaxUse=64M
RuntimeKeepFree=128M
SystemMaxUse=64M
SystemKeepFree=128M
ForwardToSyslog=no
ForwardToConsole=yes
```

##### Service Management
```bash
# Service initialization in startup script
systemctl unmask ninjarmm-agent.service
systemctl enable ninjarmm-agent.service
systemctl start ninjarmm-agent.service
```

### Important Notes

1. **System Requirements**
   - Docker with systemd support
   - Host network access
   - Privileged container capabilities

2. **Monitoring Capabilities**
   - Full host filesystem visibility (read-only)
   - System logs access
   - Network statistics
   - Process information

3. **Known Working Features**
   - System monitoring
   - Log collection
   - Network monitoring
   - Process monitoring
   - Service management

4. **Troubleshooting**
   - If journald fails, check tmpfs mounts
   - Ensure proper permissions on /sys/fs/cgroup
   - Verify systemd is running as PID 1
   - Check container logs for systemd initialization errors
   - If service is masked, verify startup script execution

### Cross-Platform Adaptation

This container can be adapted for other non-Linux systems that support Docker:

1. **FreeBSD Specifics**
   - Uses Linux compatibility layer via Docker
   - Requires host networking for proper monitoring
   - Mounts host filesystem at `/host`

2. **Adapting for Other Systems**
   - **MacOS**:
     - Update volume mounts to match MacOS paths
     - Consider using colima or similar for systemd support
     - Adjust network mode based on Docker desktop capabilities

   - **Windows**:
     - Use WSL2 backend for Docker
     - Adjust paths for Windows filesystem
     - Consider Windows-specific monitoring requirements

3. **Key Adaptation Points**
   - Volume mounts: Adjust paths based on host OS
   - Network mode: Verify host network support
   - Filesystem access: Update mount points
   - Resource limits: Adjust based on host capabilities
   - Log collection: Modify paths for host logs

4. **Common Requirements**
   - Systemd support in container
   - Host filesystem access
   - Network visibility
   - Proper service initialization
   - Log access configuration

### Configuration

#### Agent Installation URL
The NinjaOne agent installer URL is configured in the `.env` file:
```ini
NINJA_INSTALLER_URL=https://eu.ninjarmm.com/agent/installer/YOUR-INSTALLER-URL-HERE
```

To update the agent version or change the installation URL:
1. Get your new installer URL from NinjaOne dashboard
2. Update the `NINJA_INSTALLER_URL` in `.env` file
3. Rebuild the container

### Build and Run

1. Build the container:
```bash
docker-compose build
```

2. Start the container:
```bash
docker-compose up -d
```

3. Check container status:
```bash
docker-compose ps
docker-compose logs
```

4. Verify service status:
```bash
docker exec ninjaone-agent systemctl status ninjarmm-agent
