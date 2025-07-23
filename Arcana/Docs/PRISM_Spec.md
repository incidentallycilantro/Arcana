# PRISM Engine – Specification

## 🎯 Purpose
PRISM (Predictive, RAM-aware, Intelligent Shard Manager) is your AI engine.

## 🧩 Core Responsibilities

1. **Model Management**
   - Install, delete, update GGUF models
   - Maintain registry with metadata (quant, size, usage)

2. **Shard Loading**
   - Split model into chunks for on-demand loading
   - Use system RAM check before loading

3. **Speculative Engine**
   - Use small model to pre-generate likely responses
   - Swap in full model only if needed

4. **Adapter Injection**
   - Load task-specific adapters dynamically (LoRA)

5. **Disk Optimization**
   - Dedup shared weights
   - Compress unused models
   - Delta patch updates

## 🔧 Config Location

All config lives in:
~/Library/Application Support/PrivateLLMCompanion/models/

PRISM reads `.manifest.json` per model to determine load logic.