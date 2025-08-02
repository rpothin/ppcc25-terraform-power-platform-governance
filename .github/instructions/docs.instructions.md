---
description: "Documentation standards following the Diataxis framework for open-source projects"
applyTo: "docs/**"
---

# Documentation Writing Guidelines

## 🎯 Repository Context

This documentation serves as demonstration material for **"Enhancing Power Platform Governance Through Terraform: Embracing Infrastructure as Code"** (PPCC25 session).

All documentation should reflect:
- **Quickstart guide principles** – Easy to understand and follow
- **Demonstration quality** – Clear examples that teach concepts effectively
- **ClickOps to IaC transition** – Show best practices for automation adoption

---

## Diataxis Framework – Four Documentation Types

Structure **ALL** documentation according to the four quadrants, each serving distinct user needs:

### 1. Tutorials
**Learning-oriented (Study/Acquisition of skills)**
- **Purpose:** Provide a successful learning experience through guided practice
- **User need:** "Can you teach me to...?"
- **Context:** User is studying, acquiring basic competence
- **Form:** A lesson with step-by-step guidance under instructor supervision
- **Language:** "We will...", "In this tutorial, we will...", "First, do x. Now, do y."
- **Badge:**
  ```markdown
  ![Tutorial](https://img.shields.io/badge/Diataxis-Tutorial-blue?style=for-the-badge&logo=book)
  ```

### 2. How-to Guides
**Task-oriented (Work/Application of skills)**
- **Purpose:** Help accomplish a specific task or solve a real-world problem
- **User need:** "How do I...?"
- **Context:** User is working, already competent, needs to get something done
- **Form:** A series of steps addressing a concrete goal or problem
- **Language:** "This guide shows you how to...", "If you want x, do y.", "To achieve w, do z."
- **Badge:**
  ```markdown
  ![How-to Guide](https://img.shields.io/badge/Diataxis-How--to%20Guide-green?style=for-the-badge&logo=tools)
  ```

### 3. Reference
**Information-oriented (Work/Application of knowledge)**
- **Purpose:** Provide authoritative, neutral descriptions of the machinery
- **User need:** "What is...?"
- **Context:** User needs factual information while working
- **Form:** Dry, structured description following the product's architecture
- **Language:** "X inherits Y's defaults", "Sub-commands are: a, b, c", "You must use a. Never do b."
- **Badge:**
  ```markdown
  ![Reference](https://img.shields.io/badge/Diataxis-Reference-orange?style=for-the-badge&logo=library)
  ```

### 4. Explanation
**Understanding-oriented (Study/Acquisition of knowledge)**
- **Purpose:** Deepen understanding through discursive treatment of topics
- **User need:** "Why...?" or "Can you tell me about...?"
- **Context:** User steps away from work to reflect and understand
- **Form:** Discussion that illuminates context, history, and connections
- **Language:** "The reason for x is...", "W is better than z, because...", "Some users prefer w..."
- **Badge:**
  ```markdown
  ![Explanation](https://img.shields.io/badge/Diataxis-Explanation-purple?style=for-the-badge&logo=lightbulb)
  ```

---

## Critical Documentation Routing

### When to Create Each Type
- **Tutorial:** User wants to learn, get started, build confidence ("teach me", "first time using")
- **How-to Guide:** User has specific problem to solve ("how do I", "I need to achieve")
- **Reference:** User needs factual information while working (API docs, parameters, specifications)
- **Explanation:** User wants to understand bigger picture ("why", "tell me about", design decisions)

### Common Conflations to Avoid
- **Tutorial vs How-to:** Not basic vs advanced, but learning vs working context
- **Reference vs Explanation:** Not obvious vs complex, but work vs study context

---

## Documentation File Organization Rules

### Mandatory Structure Requirements
1. **Location:** All documentation MUST be in `docs/` folder at repository root
2. **File Naming:** MUST use lowercase with hyphens (e.g., `getting-started.md`, not `Getting Started.md`)
3. **Folder Structure:** Organize by Diataxis categories:

   ```text
   docs/
   ├── tutorials/
   ├── guides/
   ├── reference/
   └── explanations/
   ```

---

## Content Standards

### Universal Standards
- **Audience-aware:** Write for diverse backgrounds and skill levels
- **Time-conscious:** Be concise and direct – respect users' limited time
- **Simple and clear:** Use straightforward language, avoid unexplained jargon
- **Scannable:** Use headings, bullet points, and code blocks for easy scanning
- **Actionable:** Provide concrete examples and clear next steps
- **Accessible:** Consider different learning styles and technical backgrounds

### Writing Standards
- Start with the user's goal or problem
- Use active voice and present tense
- Include relevant code examples with syntax highlighting
- Provide context for when and why to use features
- Link to related documentation when helpful
- Include troubleshooting for common issues
- Keep paragraphs short (2-4 sentences)
- Use consistent terminology throughout

---

## Badge and Formatting Standards

### Badge Standards Enforcement
- **Badge Style:** ALL Diataxis badges MUST use `style=for-the-badge` (never `flat-square` or other styles)
- **Badge Placement:** Badge MUST appear immediately after the main H1 title, before any content
- **Badge Validation:** Use this regex pattern for validation: `!\[.*\]\(https://img\.shields\.io/badge/Diataxis-.*style=for-the-badge.*\)`

### Visual Standards Requirements
Every documentation page MUST include:
- **Diataxis Badge:** Appropriate badge immediately after main title using exact markdown from framework above
- **Time Estimates:** Formatted as "⏱️ **Estimated time**: X-Y minutes" for all procedures
- **Visual Indicators:** Use appropriately throughout content:
  - ✅ Success states and completed items
  - ⚠️ Important warnings and cautions
  - 🎯 Key points and critical information
  - 📋 Checklists and task lists
  - 🔧 Technical procedures
  - 💡 Tips and best practices

---

## Document Metadata Requirements

### Mandatory Metadata
Every documentation file MUST include after the title and badge:

```markdown
**Last Updated**: YYYY-MM-DD  
**Estimated Reading Time**: X minutes  
**Prerequisites**: [List specific requirements or "None"]
```

### Tutorial-Specific Requirements
Tutorials MUST additionally include:
- **Learning Objectives:** 2-4 clear, measurable outcomes
- **Step Numbering:** Sequential steps with validation checkpoints
- **Success Indicators:** How users know they've succeeded at each major step
- **Troubleshooting Section:** Common issues and solutions for each major step
- **Next Steps:** Clear path to related how-to guides or advanced content

#### Tutorial Validation Checklist
- [ ] Can be completed by someone new to the technology
- [ ] Each step has clear success criteria
- [ ] Troubleshooting provided for likely failure points
- [ ] Estimated time tested with actual new users
- [ ] Builds confidence rather than just completing tasks

---

## Link Management and Cross-References

### Link Validation Standards
- **Internal Links:** ALL internal links MUST be validated before publication
- **Path References:** Use relative paths from document location, validate against current repository structure
- **Broken Link Prevention:** Create placeholder files for referenced content or remove/update links
- **External Links:** Verify functionality and relevance during creation and quarterly reviews

### Cross-Reference Requirements
Every documentation file MUST include a "Related Documentation" section with:
- **Minimum:** 2 strategic related links
- **Maximum:** 5 related links to avoid overwhelming users
- **Format:** `- [Link Text](relative/path) - Brief description of relevance`
- **Strategic Selection:** Links should guide users to logical next steps or complementary information

#### Related Documentation Template
```markdown
## Related Documentation
- [Setup Guide](../guides/setup-guide.md) - Step-by-step infrastructure setup
- [Configuration Reference](../reference/terraform-config.md) - Complete parameter documentation
- [Troubleshooting Guide](../guides/troubleshooting.md) - Common issues and solutions
```

---

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

---

## Quality Assurance and Validation

### Pre-Publication Checklist
Before any documentation is published, verify:
- [ ] Document serves exactly ONE Diataxis purpose
- [ ] Badge format matches requirements (`style=for-the-badge`)
- [ ] Badge content matches document type and actual purpose
- [ ] All internal links tested and functional
- [ ] All path references match current repository structure
- [ ] Referenced files exist or are scheduled for creation
- [ ] Metadata complete and properly formatted
- [ ] Visual indicators used appropriately
- [ ] Time estimates are realistic (test with users when possible)
- [ ] Related documentation section included with 2-5 strategic links
- [ ] Examples are tested and functional
- [ ] Cross-references are accurate and helpful

### Content Validation Standards
- Every document must clearly serve ONE Diataxis purpose
- Content must match the declared documentation type
- Instructions must be validated and work reliably
- Cross-references must be accurate and helpful
- Examples must be relevant to the project context

### Automated Validation Requirements
Implement the following validation mechanisms where possible:

#### Pre-commit Validation
- Badge format validation using regex patterns
- Link existence verification for internal references
- Metadata completeness check
- Spelling and grammar validation

#### Documentation Review Checklist
- [ ] Document serves exactly ONE Diataxis purpose
- [ ] Badge matches document type and content
- [ ] All examples are tested and functional
- [ ] Cross-references are accurate and helpful
- [ ] Time estimates are realistic and tested
- [ ] Visual formatting follows standards

---

## Maintenance and Continuous Improvement

### Quarterly Maintenance Requirements
Every three months, documentation must be reviewed for:
- [ ] Link audit and update (internal and external)
- [ ] Content accuracy review against current codebase
- [ ] User feedback integration from issues and discussions
- [ ] Compliance verification against current standards
- [ ] Time estimate validation and updates
- [ ] Related documentation relevance check

### Change Management
When making changes to documentation:
- **Always check CHANGELOG.md** when making changes to any documentation files
- **Update the Unreleased section** if changes represent notable additions, changes, or fixes
- **Notable changes include:** New documentation files, structural changes, significant content updates
- **Minor changes** (typo fixes, formatting adjustments) may not require changelog updates

### User Feedback Integration
- Collect feedback from users and contributors on documentation usability
- Prioritize improvements based on user impact and frequency of issues
- Track common questions in GitHub issues to identify documentation gaps
- Use analytics (if available) to understand most-used and least-used documentation

---

## Error Prevention and Common Issues

### Common Documentation Anti-Patterns to Avoid
- **Mixed Purposes:** Documents that try to be both tutorial and reference
- **Inconsistent Badge Styles:** Using `flat-square` instead of `for-the-badge`
- **Broken Internal Links:** References to moved or deleted files
- **Missing Prerequisites:** Assuming user knowledge without stating requirements
- **Outdated Path References:** Links to old directory structures
- **Missing Time Estimates:** Users can't plan their work effectively
- **No Related Links:** Users get stuck without next steps

### Systematic Prevention Strategies
- Use templates for each Diataxis type to ensure consistency
- Validate all internal links before publishing
- Test procedures with actual users when possible
- Review documentation quarterly for accuracy and relevance
- Maintain a documentation style guide with examples
- Use automated validation where possible (linting, link checking)

---

*This documentation instruction file ensures consistent, high-quality documentation that serves users effectively while maintaining professional demonstration standards for the PPCC25 Power Platform governance project.*