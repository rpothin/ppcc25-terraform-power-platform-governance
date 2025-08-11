---
mode: ask
model: Claude Sonnet 4
description: "Comprehensive feasibility analysis for new Terraform configurations in the PPCC25 Power Platform governance demonstration repository"
---

# Terraform Configuration Feasibility Analysis

## 🎯 Context & Mission
Analyze the feasibility of implementing a new **{CONFIGURATION_TYPE}** Terraform configuration for **{RESOURCE_DESCRIPTION}** management.

**Target Resource/Provider**: {TERRAFORM_RESOURCE_DOCUMENTATION_URL}
**Configuration Class**: {res-|utl-|ptn-}*

## 📋 Systematic Analysis Framework

### Phase 1: Requirements & Compliance Assessment

#### A. Repository Standards Compliance
Evaluate alignment with established guidelines:
- **Baseline Principles**: Security by design, simplicity, modularity, reusability, clear comments
- **Terraform IaC Standards**: AVM compliance, provider management, testing requirements
- **File Organization**: Proper placement in `configurations/` with standard structure
- **Documentation Standards**: Diataxis framework adherence for any new docs

#### B. AVM Specification Compliance  
Assess against Azure Verified Module requirements:
- **Module Classification**: Verify correct `res-`, `utl-`, or `ptn-` prefix usage
- **File Structure**: Ensure all required files (main.tf, variables.tf, outputs.tf, versions.tf, tests/)
- **Testing Requirements**: Plan for minimum assertions (15+ utl, 20+ res, 25+ ptn)
- **Anti-corruption Layer**: Design discrete outputs vs. full resource exposure

#### C. Power Platform Provider Compatibility
Analyze provider-specific considerations:
- **Provider Version**: Compatibility with centralized standard `~> 3.8`
- **Resource Availability**: Confirm target resources exist in current provider version
- **Authentication**: OIDC compatibility and security requirements
- **State Management**: Backend configuration for Azure Storage with encryption

### Phase 2: Technical Architecture Analysis

#### A. Resource Design Patterns
**Variable Design**:
- Complex object types with property-level validation
- HEREDOC descriptions with examples and validation reasoning
- Actionable error messages for failed validations
- Input sanitization and security considerations

**Output Strategy**:
- Anti-corruption layer implementation
- Required summary outputs for module type
- Discrete value exposure vs. full resource objects
- Downstream integration considerations

**Lifecycle Management**:
- For `res-*` modules: lifecycle blocks for manual change tolerance
- State drift handling between Terraform and admin portal changes
- Resource update strategies and change detection

#### B. Integration Considerations
**Repository Integration**:
- Relationship with existing configurations (res-dlp-policy, res-environment, etc.)
- Shared data sources and cross-module dependencies
- Consistency with established naming and tagging patterns
- Reusability potential for future configurations

**CI/CD Pipeline Integration**:
- GitHub Actions workflow compatibility
- Validation gate requirements (fmt, validate, test)
- Security scanning and credential management
- Deployment automation considerations

### Phase 3: Implementation Planning

#### A. Development Phases
Present **2-4 implementation approaches** with clear trade-offs:

**Option 1**: [Approach Name] ⭐ RECOMMENDED
- **Complexity**: {Low|Medium|High}
- **Timeline**: {X-Y weeks}
- **Pros**: [Key advantages]
- **Cons**: [Main limitations]
- **Risk Level**: {Low|Medium|High}

## 🎯 Success Criteria

### Mandatory Deliverables
- [ ] All files pass `terraform fmt -check` and `terraform validate`
- [ ] Tests meet minimum assertion requirements for module type
- [ ] Variables use explicit types with comprehensive validation
- [ ] Outputs implement anti-corruption layer pattern
- [ ] Documentation follows repository standards
- [ ] Security baseline compliance (OIDC, no hardcoded secrets)

### Quality Indicators
- [ ] Code demonstrates PPCC25 educational objectives
- [ ] Configuration serves as effective quickstart example
- [ ] Implementation supports ClickOps to IaC transition narrative
- [ ] Documentation enables user learning and adoption
- [ ] Testing provides confidence in production usage

## 📊 Analysis Output Format

Provide structured analysis covering:

1. **Feasibility Assessment**: Go/No-Go recommendation with rationale
2. **Implementation Options**: 2-4 approaches with pros/cons analysis
3. **Recommended Approach**: Clear selection with justification
4. **Risk Register**: Identified risks with mitigation strategies
5. **Success Metrics**: Measurable outcomes and validation criteria

## 🔍 Key Questions to Address

1. **Technical Viability**: Does the provider support all required functionality?
2. **Repository Fit**: How does this align with existing patterns and standards?
3. **Complexity Management**: Can this be implemented within file size limits (200 lines)?
4. **Maintenance Burden**: What ongoing support will this configuration require?
5. **Educational Value**: How does this advance the PPCC25 learning objectives?

---

**Remember**: This analysis serves demonstration and educational purposes. Prioritize clarity, security, and reusability while maintaining alignment with baseline principles and AVM compliance where technically feasible.