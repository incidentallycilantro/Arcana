# Private LLM Companion – Architecture Guide

## 🗂️ Folder Structure

/PrivateLLMCompanion/
├── /Core/
│   ├── PRISMEngine.swift
│   ├── ModelManager.swift
│   ├── AdapterController.swift
│   ├── MemoryGraph.swift
├── /Views/
│   ├── MainView.swift
│   ├── ProjectSidebar.swift
│   ├── ChatView.swift
│   ├── TimelineView.swift
├── /Models/
│   ├── Project.swift
│   ├── ChatMessage.swift
│   ├── AssistantProfile.swift
├── /Helpers/
│   ├── UXAnimations.swift
│   ├── FileLoader.swift
│   ├── TextUtilities.swift
├── /Assets/
│   ├── Icons.xcassets
│   ├── AssistantAvatars/
├── /Docs/
│   ├── Features.md
│   ├── Architecture.md
│   ├── PRISM_Spec.md
│   ├── UX_Magic.md
│   ├── Threading_Guide.md

## ✅ Naming Conventions

- Use `PascalCase` for Swift files, classes, structs
- Use `snake_case` for asset filenames and raw data
- Folders are organized by responsibility (not MVC)
- All files include top comment: `// Created by Dylan E. | PrivateLLMCompanion`

## 📌 Guidelines

- One Swift file per feature/module
- Helper files must not store state — pure utility
- Views use SwiftUI; logic lives in ViewModels (if needed later)