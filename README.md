## Adding large CIDR range to available networking of an Azure Storage Account

```
terraform init
terraform plan
```

The outputs will show the available GitHub action CIDRs that will fit into a Storage Account's Firewall. This is less than ideal since it opens up to other IPs but it helps reduce the public exposure.
