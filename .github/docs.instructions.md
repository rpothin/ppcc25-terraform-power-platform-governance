---
description: "Documentation standards following the Diataxis framework for open-source projects"
applyTo: "docs/**"
---

# Documentation Writing Guidelines

## Diataxis Framework - Four Documentation Types

Structure ALL documentation according to the four quadrants, each serving distinct user needs:

### 1. **Tutorials** - Learning-oriented (Study/Acquisition of skills)
- **Purpose**: Provide a successful learning experience through guided practice
- **User need**: "Can you teach me to...?"
- **Context**: User is studying, acquiring basic competence
- **Form**: A lesson with step-by-step guidance under instructor supervision
- **Language**: "We will...", "In this tutorial, we will...", "First, do x. Now, do y."
- **Badge**: `![Tutorial](https://img.shields.io/badge/Diataxis-Tutorial-blue?style=for-the-badge&logo=book)`

### 2. **How-to Guides** - Task-oriented (Work/Application of skills)
- **Purpose**: Help accomplish a specific task or solve a real-world problem
- **User need**: "How do I...?"
- **Context**: User is working, already competent, needs to get something done
- **Form**: A series of steps addressing a concrete goal or problem
- **Language**: "This guide shows you how to...", "If you want x, do y.", "To achieve w, do z."
- **Badge**: `![How-to Guide](https://img.shields.io/badge/Diataxis-How--to%20Guide-green?style=for-the-badge&logo=tools)`

### 3. **Reference** - Information-oriented (Work/Application of knowledge)
- **Purpose**: Provide authoritative, neutral descriptions of the machinery
- **User need**: "What is...?"
- **Context**: User needs factual information while working
- **Form**: Dry, structured description following the product's architecture
- **Language**: "X inherits Y's defaults", "Sub-commands are: a, b, c", "You must use a. Never do b."
- **Badge**: `![Reference](https://img.shields.io/badge/Diataxis-Reference-orange?style=for-the-badge&logo=library)`

### 4. **Explanation** - Understanding-oriented (Study/Acquisition of knowledge)
- **Purpose**: Deepen understanding through discursive treatment of topics
- **User need**: "Why...?" or "Can you tell me about...?"
- **Context**: User steps away from work to reflect and understand
- **Form**: Discussion that illuminates context, history, and connections
- **Language**: "The reason for x is...", "W is better than z, because...", "Some users prefer w..."
- **Badge**: `![Explanation](https://img.shields.io/badge/Diataxis-Explanation-purple?style=for-the-badge&logo=lightbulb)`

## Critical Documentation Routing

### When to Create Each Type
- **Tutorial**: User wants to learn, get started, build confidence ("teach me", "first time using")
- **How-to Guide**: User has specific problem to solve ("how do I", "I need to achieve")
- **Reference**: User needs factual information while working (API docs, parameters, specifications)
- **Explanation**: User wants to understand bigger picture ("why", "tell me about", design decisions)

### Common Conflations to Avoid
- **Tutorial vs How-to**: Not basic vs advanced, but learning vs working context
- **Reference vs Explanation**: Not obvious vs complex, but work vs study context

## Documentation File Organization Rules

### Mandatory Structure Requirements
1. **Location**: All documentation MUST be in `docs/` folder at repository root
2. **File Naming**: MUST use lowercase with hyphens (e.g., `getting-started.md`, not `Getting Started.md`)
3. **Folder Structure**: Organize by Diataxis categories:
   ```
   docs/
   ├── tutorials/
   ├── guides/
   ├── reference/
   └── explanations/
   ```

## Content Standards

### Universal Standards
- **Audience-aware**: Write for diverse backgrounds and skill levels
- **Time-conscious**: Be concise and direct - respect users' limited time
- **Simple and clear**: Use straightforward language, avoid unexplained jargon
- **Scannable**: Use headings, bullet points, and code blocks for easy scanning
- **Actionable**: Provide concrete examples and clear next steps
- **Accessible**: Consider different learning styles and technical backgrounds

### Writing Standards
- Start with the user's goal or problem
- Use active voice and present tense
- Include relevant code examples with syntax highlighting
- Provide context for when and why to use features
- Link to related documentation when helpful
- Include troubleshooting for common issues
- Keep paragraphs short (2-4 sentences)
- Use consistent terminology throughout

### Badge Requirements
Every documentation page MUST include appropriate Diataxis badge immediately after main title:
- Place badge before any content begins
- Use exact badge markdown from the framework above
- Badge must match the document's actual type and purpose

## Repository-Specific Guidelines

### Power Platform Governance Context
- Document Power Platform provider exceptions and compliance status
- Include Azure Verified Modules (AVM) compliance information
- Reference Infrastructure as Code (IaC) best practices
- Include workflow status badges for CI/CD visibility
- Follow established README template structure for consistency

### Technical Standards
- Document all configuration options with default values
- Include time estimates for setup procedures and manual tasks
- Provide practical examples with proper syntax highlighting
- Use visual indicators (✅, ⚠️, 🎯) for better readability
- Ensure all instructions are testable and reproducible
- Link to external resources and related documentation

### Quality Assurance
- Every document must clearly serve ONE Diataxis purpose
- Content must match the declared documentation type
- Instructions must be validated and work reliably
- Cross-references must be accurate and helpful
- Examples must be relevant to the project context
