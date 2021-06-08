# Management Subscryption

## Log Analytics

This is all hapenning in Management subscription
Resource created:

1. Assign policy to enable Log Analytics and Azure Automation
   - This applies at prefix-management mgmt group level
2. Create role assignment for the policy that will deploy Log Analytics and Azure Automation (create a service principal role)
3. Deploy Log Analytics and Azure Automation

## Monitoring Solutions

This is all hapenning in Management subscription

1. Deploy solution for agent health - Agent Health solution in Azure Monitor in log analytics workspace
2. ChangeTracking solution
3. Security solution
4. SQLAssessment solution
5. VMInsights solution
6. SecurityInsights solution
7. ServiceMap solution
8. AzureActivity solution

## Landing Zone

1. Assign Enable-DDoS-VNET policy
2. Assign Deny-PublicEndpoints policy
3. Assign Enable-Encryption-In-Transit policy
4. Assign policy to prevent inbound RDP policy
5. Assign policy to enforce VM backup policy
6. Assign roleAssignment for SQL audit policy
7. Assign policy for SQL encryption policy
8. Assign policy to enable Azure Policy for AKS policy
9. Assign policy for Deny-Privileged-Containers-AKS policy
10. Assign policy for Deny-Privileged-Escalations-AKS policy
11. Assign policy to Enforce-Https-Ingress-AKS policy
12. Assign policy to enforce https for storage accounts policy
13. Assign policy to deny IP forwarding policy policy
14. Assign policy to deny subnet creation without NSG

## Diagonistic and Security

1. Assignment of policy to enforce activity logs from subscriptions to Log Analytics
2. Assignment of policy to enforce Log Analytics VM extension to Windows and Linux virtual machines
3. Assignment of policy to enforce VMSS monitoring to Log Analytics
4. Assignment of policy to enforce Windows Arc monitoring to Log Analytics
5. Assignment of policy to enforce Linux Arc monitoring to Log Analytics
6. Assignment of policy to enforce Azure Resource Diagnostics to Log Analytics
7. Assignment of policy to enforce Azure Security Center on subscriptions
8. Assignment of policy to enable ASC monitoring
9. ARM deployments to invoke template from ActivityLog diagnostics on management subscription
10. ARM deployments to invoke template from ActivityLog diagnostics on identity subscription
11. ARM deployments to invoke template from ActivityLog diagnostics on connectivity subscription
12. ARM deployments to invoke template from ASC on management subscription
13. SubscriptionSecurityConfig
    - Enable Azure defender for AppServices, Storage, AZure SQL, SQL Server on VMs, Key Vault, Resource Manager, DNS, K8s, Container registry
    - Export Azure Security Center data to Log Analytics workspace via policy

# Identity Subscription

## Identity

1. Enable policy to enforce VM Backup
2. Assign roleAssignment for the policy that will enforce VM Backup
3. Assign policy to prevent creation of puplic IP addresses
4. Assign policy to prevent inbound RDP
5. Assign policy to prevent subnet creation without associated NSG

# Connectivity Subscription

## Connectivity (Hub enabled)

1. Assignment of policy to enable DdoS (This is an existing azure policy "Virtual networks should be protected by Azure DDoS Protection Standard")
2. Enable DDoS Protction plan
3. VPN Gateway
   - Public IP Address
   - Deploy virtual network hub
   - Deploy virtual network
   - Deploy virtual network gateway
4. Express Route
   - Public IP Address
   - Deploy virtual Network Gateways
5. Firewall policies

## Corp Connected LZ

1. Policy assignment to connect corp landing zones via virtual network peering to the virtual network in the connectivity subscription.
   - Deploy-VNET-HubSpoke policy
2. Deploy VNET peering with HUB (template defined in "Deploy-VNET-HubSpoke" policy)

## Azure Operations

In Management subscription

1. Create a userAssignedIdentities
2. Create a KeyVault for storing github cred infos
3.
