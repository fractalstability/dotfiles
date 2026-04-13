# Project Conventions

## Context
These conventions apply to embedded systems, drone/UAS, geospatial, and robotics projects.
Primary targets: macOS (Apple Silicon), Linux (Raspberry Pi, Jetson), RP2350, STM32.

---

## Python Standards
- Python 3.11+ minimum; use `pyproject.toml` for packaging
- Type hints required on all public functions and class methods
- Formatter: `ruff format`; Linter: `ruff check` (replaces flake8/isort/black)
- Max line length: 100 characters
- Use `asyncio` for all I/O-bound concurrent work; avoid threading except for CPU-bound tasks
- Prefer dataclasses or Pydantic models over raw dicts for structured data
- Exception handling: always catch specific exceptions; never bare `except:`

### Preferred Libraries
| Domain | Library |
|---|---|
| Numerics / arrays | `numpy`, `scipy` |
| Async I/O | `asyncio`, `aiohttp`, `uvloop` |
| MAVLink / drone comms | `pymavlink`, `mavsdk` |
| Geospatial | `pyproj`, `shapely`, `rasterio`, `GDAL` |
| Image processing | `opencv-python`, `Pillow` |
| Serial / hardware | `pyserial`, `smbus2` |
| Data validation | `pydantic` |
| CLI tooling | `typer`, `rich` |
| Testing | `pytest`, `pytest-asyncio` |

---

## Rust Standards
- Edition: 2021
- Use `clippy` with `#![warn(clippy::all, clippy::pedantic)]`
- Prefer `thiserror` for library errors, `anyhow` for application errors
- Use `tokio` for async runtime; `embassy` for bare-metal/embedded targets
- Avoid `unwrap()` in library code; use `?` propagation
- Target `no_std` + `no_alloc` where feasible for embedded (RP2350, STM32)
- Serialization: `serde` + `serde_json` / `postcard` for embedded

### Embedded / Drone-Specific Rules
- All hardware abstraction behind traits (HAL pattern)
- Interrupt handlers: keep minimal, defer to task queues
- Use fixed-point math (`fixed` crate) over floats where precision allows on MCUs
- Document register maps and timing constraints inline
- MAVLink framing: use `mavlink` crate; validate CRC before parsing

---

## Git Commit Style (Conventional Commits)
```
<type>(<scope>): <short imperative summary>

[optional body — wrap at 72 chars]
[optional footer: BREAKING CHANGE, Closes #n]
```

**Types:** `feat` | `fix` | `refactor` | `perf` | `docs` | `test` | `chore` | `ci` | `build`

**Scopes (project-dependent):** `mavlink` | `imu` | `nav` | `gcs` | `slam` | `lidar` | `cam` | `hw` | `infra`

**Examples:**
```
feat(mavlink): add COMMAND_LONG handler for RTL
fix(imu): correct quaternion normalization edge case at singularity
docs(conventions): add Rust embedded HAL pattern notes
```

- One logical change per commit; squash WIP commits before merging
- Branch naming: `feat/`, `fix/`, `chore/` prefixes
- Sign commits where possible (`git commit -S`)

---

## Project Structure (UAS / Embedded)
```
project/
├── src/           # application source
├── hal/           # hardware abstraction layer
├── proto/         # MAVLink / protobuf definitions
├── tests/         # pytest or cargo test
├── scripts/       # utility shell/Python scripts
├── docs/          # design docs, wiring diagrams
├── CONVENTIONS.md
└── README.md
```

---

## Code Review Checklist
- [ ] No hardcoded IPs, ports, or credentials (use env vars or config files)
- [ ] All public APIs have docstrings/doc comments
- [ ] Async code has cancellation handling
- [ ] Hardware drivers handle disconnection/reconnection gracefully
- [ ] Safety-critical paths have explicit error returns, not panics
