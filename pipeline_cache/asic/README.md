# SKY130 core-macro implementation

This directory implements `pipeline_cache` as a core macro, not a standalone
chip or a foundry-qualified tapeout. Physical verification and timing results
must be reviewed before making portfolio claims. Exported GDSII passes the flow's
DRC/LVS/antenna and setup/hold checks; electrical slew/capacitance warnings remain.
See the repository root README and `results/` for evidence and limitations.

## Configuration

- LibreLane 3.0.16, checkout `01ddb25e4424f6f5aaf6b951b14a2b6fdcf737c0`.
- SKY130A PDK revision `8afc8346a57fe1ab7934ba5a6056ea8b43078e71`.
- `sky130_fd_sc_hd` standard cells; no SRAM macros.
- Four lines of four words in each cache: 64 bytes per cache, write-back D-cache.
- 50 ns clock period (20 MHz), 35% initial core utilization.
- Slang SystemVerilog frontend; simulation assertions excluded from synthesis.

The wrapper retains the external-memory handshakes and fault signal. Retirement
trace and counters are unconnected and may be optimized away. Instruction memory
is read-only, so its constant write-data and strobe outputs are not macro pins.
The CPU and cache RTL and their simulation interfaces are unchanged.

## Timing contract

`constraints.sdc` assumes external logic uses the same clock. Inputs have
1–10 ns arrival delays and 0.5 ns transition; outputs have 1–10 ns required
delays and 20 fF loads. These are provisional integration assumptions, not
measured board or pad timing. Reset asserts asynchronously in RTL; integration
must release reset synchronously to this clock and meet recovery/removal timing.
No blanket reset false path is applied. No PLL, reset synchronizer, pads,
external-memory implementation, or scan infrastructure is included.

## Run from the repository root

```bash
make -f pipeline_cache/Makefile test
bash pipeline_cache/asic/run.sh synth
# After reviewing synthesis, constraints, and warnings:
bash pipeline_cache/asic/run.sh full
```

`synth` stops after pre-placement static timing analysis. `full` starts a fresh
complete implementation. Tags default to timestamps; choose a unique `ASIC_TAG`
for each run. Existing runs are never overwritten by the script.

Defaults:

| Variable | Default |
|---|---|
| `LIBRELANE_APPIMAGE` | `~/eda/appimages/librelane-3.0.16-x86_64.AppImage` |
| `PDK_ROOT` | `~/eda/pdks` |
| `ASIC_RUNS` | `~/eda/asic-runs/pipeline_cache` |
| `ASIC_JOBS` | `8` |

The launcher resolves source paths into an external configuration snapshot.
Logs, intermediate files, reports, and final views live under `$ASIC_RUNS/runs`.
For better filesystem performance, override `ASIC_RUNS` with a Linux path.
Keep the checkout revision and PDK revision fixed for reproducibility; retain
the source commit/diff alongside reports because source files are not copied.

## Review gates

1. All CPU/cache/fault regressions pass.
2. Elaboration succeeds; review lint warnings rather than treating warning
   counts as proof of correctness.
3. Synthesis has no unresolved cells, unintended latches, or structural errors.
   Inspect mapped area, register count, memory mapping, and critical timing paths.
4. Review placement utilization/congestion, clock tree, power connectivity,
   extracted setup/hold timing, slew, capacitance, and unconstrained paths.
5. Require passing DRC, LVS, antenna, and disconnected-pin checks. Document
   warnings, skipped checks, and limitations. Do not disable checks to claim pass.
6. Retain final GDSII/LEF/netlist, metrics, timing and verification reports,
   tool/PDK versions, and layout screenshots as portfolio evidence.

The final configuration enables post-global-routing design and timing repair,
with a 0.3 ns hold margin. This resolved the first run's reset-removal violations.
Published worst extracted slack is +23.107 ns setup and +0.0383 ns hold/removal.
Maximum slew/capacitance warnings remain; this is not full electrical signoff.
