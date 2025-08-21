---
mode: ask
model: Claude Sonnet 4
description: "Comprehensive feasibility analysis for new Terraform configurations in the PPCC25 Power Platform governance demonstration repository"
---

# Terraform Configuration Feasibility Analysis

## 🎯 Context & Mission

**OBJECTIVE**: Analyze the feasibility of implementing a new **{CONFIGURATION_TYPE}** Terraform configuration for **{RESOURCE_DESCRIPTION}** management in the PPCC25 Power Platform governance demonstration.

**Required Inputs** (Replace before analysis):
- `{CONFIGURATION_TYPE}`: Specific module type (res-|utl-|ptn-)
- `{RESOURCE_DESCRIPTION}`: Target resource or pattern to implement
- `{TERRAFORM_RESOURCE_DOCUMENTATION_URL}`: Provider documentation link
- `{BUSINESS_JUSTIFICATION}`: Why this configuration is needed
- `{TARGET_AUDIENCE}`: Who will use this configuration

## 📋 Systematic Analysis Framework

### Phase 1: Compliance & Standards Verification

#### A. Repository Standards Checklist
**AI Agent: Verify each item with specific evidence**

```yaml
Security_by_Design:
  ✓ OIDC_Authentication: # Can this use OIDC exclusively?
  ✓ No_Hardcoded_Secrets: # Are all sensitive values parameterized?
  ✓ Least_Privilege: # Does this follow minimum permission model?
  ✓ Input_Validation: # Can all inputs be validated?

Simplicity_Metrics:
  ✓ File_Size: # Can each file stay under 200 lines?
  ✓ Complexity: # Is cyclomatic complexity under 10?
  ✓ Nesting: # Can we maintain max 3 levels nesting?
  
Modularity:
  ✓ Single_Responsibility: # One clear purpose per file?
  ✓ Logical_Boundaries: # Clear separation of concerns?
  
Reusability:
  ✓ Parameterization: # Fully configurable via variables?
  ✓ No_Duplication: # Avoiding copy-paste patterns?
```

#### B. AVM Specification Compliance Matrix
**AI Agent: Complete this assessment table**

| AVM Requirement               | Supported  | Implementation Notes | Risk Level   |
| ----------------------------- | ---------- | -------------------- | ------------ |
| Module prefix (res/utl/ptn)   | ☐ Yes ☐ No |                      | Low/Med/High |
| Required files structure      | ☐ Yes ☐ No |                      | Low/Med/High |
| Test assertions (15+/20+/25+) | ☐ Yes ☐ No |                      | Low/Med/High |
| Anti-corruption outputs       | ☐ Yes ☐ No |                      | Low/Med/High |
| Version constraints           | ☐ Yes ☐ No |                      | Low/Med/High |

#### C. Power Platform Provider Capability Assessment
**AI Agent: Analyze provider documentation and answer**

```markdown
Provider Analysis:
1. Does provider v3.8+ support this resource? [YES/NO/PARTIAL]
   - If PARTIAL, what's missing: _______________
   
2. OIDC authentication compatible? [YES/NO]
   - Required workarounds: _______________
   
3. Known limitations or issues:
   - [ ] State drift concerns
   - [ ] API rate limiting
   - [ ] Resource dependencies
   - [ ] Update restrictions
```

### Phase 2: Technical Design Analysis

#### A. Configuration Architecture Decision Record

**AI Agent: Complete this ADR template**

```markdown
## Decision: {Configuration Design Approach}

### Status
[PROPOSED]

### Context
- Business need: {BUSINESS_JUSTIFICATION}
- Technical constraints: [List key constraints]
- Integration requirements: [List dependencies]

### Decision Drivers (prioritized)
1. Security compliance (MUST have)
2. Simplicity for demonstration (SHOULD have)
3. Reusability across environments (SHOULD have)
4. Educational clarity (MUST have)

### Considered Options

#### Option 1: {Approach Name} ⭐ RECOMMENDED
**Implementation Pattern**:
```terraform
# Example structure
module "example" {
  source = "./modules/{module-name}"
  # Key design pattern illustration
}
```

**Metrics**:
- Lines of Code: ~{number}
- Files Required: {number}
- Complexity Score: {1-10}
- Development Effort: {hours/days}

**Trade-offs**:
- ✅ Pros: [List 3-5 advantages]
- ⚠️ Cons: [List 2-3 limitations]
- 🚨 Risks: [List critical risks]

#### Option 2: {Alternative Approach}
[Repeat structure above]

### Decision Outcome
Selected Option {N} because:
1. [Primary reason aligned with decision drivers]
2. [Secondary supporting reason]
3. [Risk mitigation consideration]
```

#### B. Resource Dependency Mapping
**AI Agent: Identify all dependencies**

```yaml
Direct_Dependencies:
  - provider: power-platform ~> 3.8
  - provider: azurerm ~> 4.0
  - data_sources:
    - [ ] power_platform_environment
    - [ ] azurerm_subscription
    - [ ] Other: _________

Cross_Module_Dependencies:
  - [ ] res-environment (environment creation)
  - [ ] res-dlp-policy (policy assignment)
  - [ ] utl-naming (naming conventions)
  - [ ] Other: _________

External_Dependencies:
  - [ ] Azure AD configuration
  - [ ] Power Platform admin center settings
  - [ ] Network connectivity
  - [ ] Other: _________
```

### Phase 3: Risk Assessment & Mitigation

#### A. Risk Register
**AI Agent: Complete risk analysis with specific mitigations**

| Risk Category | Specific Risk                     | Probability  | Impact       | Mitigation Strategy | Owner |
| ------------- | --------------------------------- | ------------ | ------------ | ------------------- | ----- |
| Technical     | Provider limitation for {feature} | High/Med/Low | High/Med/Low | [Specific action]   | Dev   |
| Security      | Credential exposure in logs       | High/Med/Low | High/Med/Low | [Specific action]   | Dev   |
| Operational   | State drift with manual changes   | High/Med/Low | High/Med/Low | [Specific action]   | Ops   |
| Educational   | Complexity exceeds demo scope     | High/Med/Low | High/Med/Low | [Specific action]   | PM    |

#### B. Failure Mode Analysis
**AI Agent: Identify potential failure points**

```markdown
Critical Failure Points:
1. **Authentication Failure**
   - Trigger: OIDC token expiration
   - Impact: Complete deployment failure
   - Detection: Provider error messages
   - Recovery: Token refresh automation

2. **Resource Conflict**
   - Trigger: [Specific scenario]
   - Impact: [Specific outcome]
   - Detection: [How to identify]
   - Recovery: [Resolution steps]

[Add 2-3 more critical points]
```

### Phase 4: Implementation Roadmap

#### A. Development Phases
**AI Agent: Create actionable timeline**

```markdown
## Sprint 1 (Week 1-2): Foundation
- [ ] Create module structure in `configurations/{name}/`
- [ ] Implement core resource definitions
- [ ] Add basic variable validation
- [ ] Create minimal test case
- Deliverable: Working prototype with 1 test passing

## Sprint 2 (Week 3-4): Enhancement
- [ ] Complete variable validation rules
- [ ] Implement anti-corruption outputs
- [ ] Add comprehensive error handling
- [ ] Expand test coverage to 50%
- Deliverable: Feature-complete module

## Sprint 3 (Week 5-6): Production Ready
- [ ] Complete test assertions (15+/20+/25+)
- [ ] Add documentation (README, examples)
- [ ] Security review and remediation
- [ ] Integration testing with workflows
- Deliverable: Production-ready configuration
```

#### B. Success Metrics
**AI Agent: Define measurable outcomes**

```yaml
Quantitative_Metrics:
  code_quality:
    - terraform_fmt: 100% compliance
    - terraform_validate: 0 errors
    - test_coverage: >80%
    - file_size: <200 lines per file
    - complexity: <10 cyclomatic
  
  performance:
    - apply_time: <5 minutes
    - state_size: <100KB
    - api_calls: <50 per apply

Qualitative_Metrics:
  educational_value:
    - [ ] Clear demonstration of IaC benefits
    - [ ] Obvious improvement over ClickOps
    - [ ] Reusable patterns demonstrated
  
  user_experience:
    - [ ] Intuitive variable names
    - [ ] Helpful error messages
    - [ ] Comprehensive examples
```

## 📊 Executive Summary Template

**AI Agent: Complete after analysis**

```markdown
### Recommendation: [GO / NO-GO / CONDITIONAL]

**One-Line Summary**: {Clear statement of feasibility}

**Key Findings**:
1. **Technical Feasibility**: [High/Medium/Low] - {One sentence explanation}
2. **Compliance Status**: [Full/Partial/None] - {Key gaps if any}
3. **Resource Investment**: {X} person-days across {Y} weeks
4. **Risk Level**: [Low/Medium/High] - {Primary risk factor}

**Recommended Path Forward**:
- If GO: Start with Option {N} approach, beginning {date}
- If NO-GO: {Alternative solution or deferral reason}
- If CONDITIONAL: {Specific conditions that must be met}

**Critical Success Factors**:
1. {Most important requirement}
2. {Second most important}
3. {Third most important}

**Next Steps** (if approved):
1. [ ] {Immediate action item}
2. [ ] {Second action within 48 hours}
3. [ ] {Third action within 1 week}
```

## 🔍 Analysis Quality Checklist

**AI Agent: Verify before submitting analysis**

- [ ] All template sections completed with specific details
- [ ] At least 2 implementation options analyzed
- [ ] Risk mitigation strategies are actionable
- [ ] Timeline is realistic and phased
- [ ] Success metrics are measurable
- [ ] Compliance assessment is evidence-based
- [ ] Educational value is clearly articulated
- [ ] Security considerations thoroughly addressed

## 🤖 AI Agent Instructions

### How to Use This Template

1. **Replace all placeholders** in curly braces with actual values
2. **Complete all checklists** with specific evidence
3. **Fill all tables** with concrete data
4. **Provide code examples** where indicated
5. **Generate executive summary** only after full analysis

### Response Format

Structure your analysis as:
1. Executive Summary (2-3 paragraphs max)
2. Detailed Analysis (following template sections)
3. Appendices (if needed for technical details)

### Critical Reminders

- **Security First**: Never suggest approaches that compromise security
- **Simplicity Matters**: If it's too complex to explain, it's too complex to implement
- **Educational Focus**: Every decision should support learning objectives
- **Evidence-Based**: Support all assessments with specific examples or documentation