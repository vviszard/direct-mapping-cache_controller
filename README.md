# Direct Mapped Cache Controller
A fully functional direct mapped cache controller implemented in Verilog RTL, simulated using Icarus Verilog and GTKWave.

---

## Cache Specifications

| Parameter | Value |
|---|---|
| Cache Size | 1 KB |
| Block Size | 16 bytes (128 bits) |
| Number of Cache Lines | 64 |
| Address Width | 32 bits |
| Mapping Policy | Direct Mapped |
| Write Policy | Write-back with dirty bit |
| Word Size | 32 bits (4 words per block) |

### Address Breakdown
```
| TAG (22 bits) | INDEX (6 bits) | OFFSET (4 bits) |
  addr[31:10]     addr[9:4]         addr[3:0]
```

---

## Architecture

The design is split into three modules with clear separation of responsibilities:

```
direct_cache.v          (top level — connects everything)
├── cache_array.v       (dumb storage — arrays + hit logic)
└── cache_controller.v  (FSM brain — controls all modules)
```

### Module Descriptions

**cache_array.v** — Pure storage module. Holds four internal arrays: valid, tag, data, and dirty. Computes hit and dirty signals combinationally. Does not make any decisions — only stores and reports.

**cache_controller.v** — Moore FSM with four states. Makes all control decisions. Talks to the processor, cache array, and main memory. Handles hits, misses, and dirty writebacks.

**direct_cache.v** — Top level wrapper. Instantiates and connects both submodules. Performs word extraction using offset bits to serve a single 32-bit word to the processor from the 128-bit cache block.

---

## FSM State Diagram

```
            proc_req=0
  ┌──────────────────────────────┐
  ▼                              │
[IDLE] ──proc_req=1──► [COMPARE] ───hit=1──► IDLE
                           │
                         hit=0
                           │
                           ▼
[UPDATE] ◄─mem_ready=1─ [FETCH]
    │                      │
    │                 mem_ready=0
    └──────────────► COMPARE
```

| State | Active Signals | Description |
|---|---|---|
| IDLE | none | Waiting for processor request |
| COMPARE | proc_stall | Check valid bit and tag. Hit → serve data. Miss → fetch. |
| FETCH | proc_stall, mem_req, mem_addr | Request block from main memory. Wait for mem_ready. |
| UPDATE | proc_stall, store_in, (mem_wr if dirty) | Write new block into cache. Writeback dirty line if needed. |

---

## Interface Signals

| Signal | Width | Direction | Description |
|---|---|---|---|
| clk | 1 | IN | System clock |
| rst | 1 | IN | Active high reset |
| proc_req | 1 | IN | Processor request |
| rd_wr | 1 | IN | 1 = read, 0 = write |
| addr | 32 | IN | Address from processor |
| proc_wr_data | 32 | IN | Write data from processor |
| mem_data | 128 | IN | Block from main memory on miss |
| mem_ready | 1 | IN | Memory data ready signal |
| proc_stall | 1 | OUT | Stall processor during miss |
| mem_req | 1 | OUT | Request main memory |
| mem_wr | 1 | OUT | Write to memory (dirty writeback) |
| mem_addr | 32 | OUT | Address sent to memory |
| proc_data | 32 | OUT | Word returned to processor |

---

## Simulation Results

### Monitor Output
![Simulation Monitor Output](https://raw.githubusercontent.com/vviszard/direct-mapping-cache_controller/main/reports/direct_cache_output.png)

### GTKWave Waveform
![GTKWave Waveform](https://raw.githubusercontent.com/vviszard/direct-mapping-cache_controller/main/reports/direct_cache_waveform.png)

### Test Cases

| Test | Address | Operation | Expected | Result |
|---|---|---|---|---|
| 1 | 0x00000013 | Read Miss | FETCH from memory, serve data | ✓ Pass |
| 2 | 0x00000013 | Read Hit | Immediate hit, no stall | ✓ Pass |
| 3 | 0x00000013 | Write Hit | Update word, dirty=1 | ✓ Pass |
| 4 | 0x00001234 | Write Miss | Fetch block, then write | ✓ Pass |
| 5 | 0x0000FC10 | Dirty Eviction | Writeback old block, fetch new | ✓ Pass |

---

## How to Simulate

### Requirements
- [Icarus Verilog](http://iverilog.icarus.com/)
- [GTKWave](http://gtkwave.sourceforge.net/)

### Steps

```bash
# Clone the repo
git clone https://github.com/vviszard/direct-mapping-cache_controller.git
cd direct-mapping-cache_controller

# Compile
iverilog -o cache_sim testbench/direct_cache_tb.v src/direct_cache.v src/cache_controller.v src/cache_array.v

# Run simulation
vvp cache_sim

# View waveforms
gtkwave dump.vcd
```

---

## Repository Structure

```
direct-mapping-cache_controller/
├── src/
│   ├── cache_array.v        — storage arrays, hit logic
│   ├── cache_controller.v   — FSM controller
│   └── direct_cache.v       — top level module
├── testbench/
│   └── direct_cache_tb.v    — 5 test cases
├── reports/
│   ├── direct_cache_output.png    — monitor output
│   └── direct_cache_waveform.png  — GTKWave waveform
├── .gitignore
└── README.md
```

---

## Key RTL Concepts Demonstrated

- **Moore FSM design** — three always block style (state register, next state logic, output logic)
- **Latch prevention** — default-then-override pattern in combinational always blocks
- **Write-back cache policy** — dirty bit tracking and eviction handling
- **Variable part select** — `+:` operator for word extraction from cache block
- **Synchronous reset** — active high, clears valid and dirty arrays
- **Blocking vs non-blocking assignments** — correct usage in sequential and combinational blocks

---

## Roadmap

- [ ] 2-way set-associative cache with LRU replacement
- [ ] N-way parameterised set-associative cache
- [ ] FPGA implementation on Xilinx board using BRAM
- [ ] Pipelined processor with cache integration

---

## References

- NPTEL — Computer Architecture and Organisation, Prof. Indranil Sengupta, IIT Kharagpur
- Patterson and Hennessy — Computer Organisation and Design
