# RabbitMQ Peer Discovery Foundry

This is a Foundry-based implementation of RabbitMQ [peer discovery interface](https://www.rabbitmq.com/blog/2018/02/12/peer-discovery-subsystem-in-rabbitmq-3-7/)
(new in 3.7.0, previously available in the [rabbitmq-autocluster plugin](https://github.com/rabbitmq/rabbitmq-autocluster)
by Gavin Roy).

This plugin performs peer discovery using Foundry API as its sole data source.

Please familiarize yourself with [RabbitMQ clustering fundamentals](https://rabbitmq.com/clustering.html) before attempting
to use it.

Cluster provisioning and most of Day 2 operations such as [proper monitoring](https://rabbitmq.com/monitoring.html)
are not in scope for this plugin.

This plugin is based on the original [RabbitMQ Peer Discovery Kubernetes Plugin](https://github.com/rabbitmq/rabbitmq-peer-discovery-k8s).

## Supported RabbitMQ Versions

This plugin requires RabbitMQ 3.7.0 or later.

Different RabbitMQ releases may require specific releases of the plugin.

For a potential Foundry-based peer discovery and cluster formation
mechanism that supports 3.6.x, see [rabbitmq-autocluster](https://github.com/rabbitmq/rabbitmq-autocluster).

## Installation

As with any [plugin](https://rabbitmq.com/plugins.html), this plugin must be enabled before it
can be used. Peer discovery plugins must be [enabled](https://rabbitmq.com//plugins.html#basics) or [preconfigured](https://rabbitmq.com//plugins.html#enabled-plugins-file)
before first node boot:

```
rabbitmq-plugins --offline enable rabbitmq_peer_discovery_foundry
```

## Documentation

See [RabbitMQ Cluster Formation guide](https://www.rabbitmq.com/cluster-formation.html) for an overview
of the peer discovery subsystem, general configurable values and troubleshooting tips.

## License

[Licensed under the MPL](LICENSE-MPL-RabbitMQ), same as RabbitMQ server.

## Copyright

(c) Pivotal Software Inc., 2007-2019.
(c) Hitachi Vantara, 2019-2021.
