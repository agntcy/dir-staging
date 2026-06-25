# Getting Started

Choose your path based on your goal:

## I want to use Directory (connect to public staging)

**Goal:** Connect your application to the existing Directory network to discover agents.

**Prerequisites:** You'll need a SPIRE server in your environment.

**Next Step:** Follow the [Client Onboarding Guide](../onboarding/README.md).

## I want to deploy my own Directory instance

**Goal:** Run your own Directory instance for local testing or private deployment.

**Prerequisites:** Kubernetes cluster (Kind, Minikube, or cloud provider)

**Next Step:** See [Getting Started](https://docs.agntcy.org/dir/getting-started/) (Helm or GitOps/Argo CD).

## I want to deploy AND join the public network

**Goal:** Run your own Directory instance and federate with the public staging network.

**Prerequisites:** Kubernetes cluster + SPIRE knowledge

**Next Steps:**

1. Deploy your Directory instance (see [Getting Started](https://docs.agntcy.org/dir/getting-started/))
2. Setup federation (see [Client Onboarding Guide](../onboarding/README.md) after deployment)

As of `dir` `v1.3.0`, the Helm chart provides a default DHT bootstrap address for the public testbed. In most cases you should leave bootstrap-peer settings unset in your values unless you intentionally need to override that default.

## Related Documentation

- [Federation Profiles](dir-federation-profiles.md) — compare `https_web` and `https_spiffe` bundle endpoint profiles
- [Partner Federation with Prod](dir-federation-setup.md) — federate with the public Directory at `spire.ads.outshift.io`
- [OIDC/SPIFFE Authentication Gateway](dir-oidc-gateway.md) — enable remote `dirctl`, SDK, or automation access
