# Open5GS 5G SA Core + UERANSIM Docker Lab

A fully containerized 5G Standalone lab built from source using multi-stage Docker builds. Similar implementations exist, but this one aims to keep it simple.

## Architecture

```
┌───────────────────────────────────────────────────────────────────┐
│  Network 1: 5g-cn (Dualstack) - Core Network                      │
│                                                                   │
│  ┌─────┐ ┌─────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌─────┐ ┌──────┐      │
│  │ NRF │ │ SCP │ │ AUSF │ │ UDM  │ │ UDR  │ │ PCF │ │ NSSF │      │
│  └─────┘ └─────┘ └──────┘ └──────┘ └──────┘ └─────┘ └──────┘      │
│  ┌─────┐ ┌──────┐ ┌────┐ ┌───────┐ ┌────────────────────────┐     │
│  │ BSF │ │ SEPP │ │ DB │ │ WebUI │ │ Monitoring (Prom+Graf) │     │
│  └─────┘ └──────┘ └────┘ └───────┘ └────────────────────────┘     │
│                                                                   │
│  ┌─────────────┐  ┌─────────────┐  (dual-homed into 5g-ran)       │
│  │ AMF ●───────┼──│ UPF ●───────┼──────────────────────────────┐  │
│  │  (SBI+NGAP) │  │  (PFCP+GTP) │                              │  │
│  └─────────────┘  └─────────────┘                              │  │
│        │                │                                      │  │
├────────┼────────────────┼──────────────────────────────────────┘  │
└────────┼────────────────┼─────────────────────────────────────────┘
         │                │
┌────────┼────────────────┼─────────────────────────────────────────┐
│  Network 2: 5g-ran (Dualstack) - RAN                              │
│        │                │                                         │
│  ┌─────┴───┐      ┌─────┴───┐                                     │
│  │ AMF     │      │ UPF     │                                     │
│  │ (NGAP)  │◄─────│ (GTP-U) │◄──┐                                 │
│  └────┬────┘      └─────────┘   │                                 │
│       │                         │                                 │
│  ┌────┴────┐              ┌─────┴───┐                             │
│  │   gNB   │──────────────│   UE    │                             │
│  └─────────┘              └─────────┘                             │
└───────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- Docker Engine 24+ with Compose V2
- At least 8 GB RAM (build stage is memory-intensive)
- `/dev/net/tun` available on the host (for UPF and UE TUN devices)

## Quick Start

### 1. Build images

```bash
docker compose build
```

The first build compiles Open5GS and UERANSIM from source. Subsequent builds use Docker layer cache.

### 2. Start the core network

```bash
docker compose up -d
```

### 3. Register a test subscriber

You can use the WebUI at `http://localhost:9999` (admin / 1423)

Click on the + icon in the bottom right and add the IMSI, Subscriber key, Operator key from ue.yaml configuration

### 4. Verify

```bash
# Check gNB connected to AMF
docker logs fiveg-ran-gnb

# Check UE registration and PDU session
docker logs fiveg-ran-ue

# Test connectivity from UE
docker exec -it fiveg-ran-ue bash
ping -I uesimtun0 8.8.8.8
```

## Monitoring

- **Prometheus**: http://localhost:9091
- **Grafana**: http://localhost:3000 (admin / admin)

Open5GS exposes Prometheus metrics on port 9090 from AMF, SMF, UPF, and PCF. The Prometheus scrape config is pre-configured to collect from all four. Grafana ships with the Prometheus datasource auto-provisioned.

Currently supported metrics include active UE count, session counts, and various NAS/NGAP counters from AMF and SMF. Note that UPF data-plane metrics are disabled upstream due to performance impact (see open5gs/open5gs#2210).

## Configuration

All NF configs live in `configs/open5gs/`. Key points:

- All SBI interfaces use Docker DNS names for inter-NF communication
- NFs discover each other via NRF through the SCP (indirect communication model)
- AMF's NGAP and UPF's GTP-U are static addresses to ensure UE connectivity and are reachable from the `5g-ran` network
- PLMN is `001/01`, TAC is `1`, SST is `1` (matching the UERANSIM configs)
- MongoDB URI defaults to `mongodb://fiveg-cn-db/open5gs` for NFs that need DB access (UDR, PCF)

### Customizing

To change the PLMN, update all of: `nrf.yaml`, `amf.yaml`, `gnb.yaml`, `ue.yaml`, and re-register subscribers.

To add more UEs, duplicate `configs/ueransim/ue.yaml` with different IMSI/SUPI values, add corresponding subscriber entries in MongoDB, and add new services in the compose file.

## Stopping / Cleanup

```bash
docker compose down            # Stop and remove containers
docker compose down -v         # Also remove volumes (wipes DB)
```

## Troubleshooting

**gNB fails SCTP connection to AMF**: Verify AMF is up and both containers share the `5g-ran` network. Check `docker logs fiveg-cn-amf` for NGAP bind errors.

**UE registration fails with FIVEG_SERVICES_NOT_ALLOWED**: Subscriber not registered in MongoDB, or PLMN/K/OPc mismatch between `ue.yaml` and the DB entry.

**No internet from UE (ping fails via uesimtun0)**: The UPF container needs `NET_ADMIN` and `/dev/net/tun`. Also ensure the host allows IP forwarding. Check `docker exec fiveg-cn-upf ip addr show ogstun`.

**Build fails OOM**: Open5GS meson build can be memory-hungry. Ensure at least 4 GB available to Docker. You can also limit parallelism by editing the Dockerfile to use `ninja -C build -j2`.

## Notes on SEPP

The SEPP config included here is minimal. In a real roaming scenario you would need TLS certificates and a peer SEPP. For this single-PLMN lab, SEPP will start but won't be exercised unless you set up a second core with a different PLMN.
