# ehr-cloud-shield
A secure hybrid cloud architecture for healthcare EHR management with automated HIPAA &amp; GDPR compliance enforcement using Hyperledger Fabric, AWS, and smart contracts.


ehr-cloud-shield is a research-backed hybrid cloud architecture designed 
for secure Electronic Health Record (EHR) management across multi-organizational 
healthcare environments.

The system integrates a permissioned blockchain layer (Hyperledger Fabric) with 
AWS cloud infrastructure and a private on-premise layer, enforcing HIPAA and GDPR 
compliance automatically via smart contracts — eliminating reliance on manual 
auditing and periodic policy reviews.

Key Features:
- Attribute-Based Access Control (ABAC) for fine-grained PHI access
- Smart contract-based real-time compliance verification (HIPAA + GDPR)
- Immutable audit trails and cryptographic protection via Hyperledger Fabric
- IPFS off-chain storage with patient-controlled key management
- HL7 FHIR-compatible data exchange for healthcare interoperability
- AWS infrastructure provisioned via Terraform (demo artifact)
- Multi-CA trust model for patients, hospitals, and research facilities

Stack: AWS · Hyperledger Fabric · IPFS · Terraform · HL7 FHIR · Smart Contracts
