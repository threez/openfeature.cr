# openfeature [![.github/workflows/ci.yml](https://github.com/threez/openfeature.cr/actions/workflows/ci.yml/badge.svg)](https://github.com/threez/openfeature.cr/actions/workflows/ci.yml) [![https://threez.github.io/openfeature.cr/](https://badgen.net/badge/api/documentation/green)](https://threez.github.io/openfeature.cr/)

OpenFeature is an open specification that provides a vendor-agnostic,
community-driven API for feature flagging that works with your favorite
feature flag management tool or in-house solution.

Feature flags are a software development technique that allows teams to
enable, disable or change the behavior of certain features or code paths
in a product or service, without modifying the source code.

Standardizing feature flags unifies tools and vendors behind a common
interface, avoiding vendor lock-in at the code level. It provides a
framework for building extensions and integrations that can be shared
across the community.

This library implements the crystal version of this specification.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     openfeature:
       github: threez/openfeature.cr
   ```

2. Run `shards install`

## Usage

```crystal
require "openfeature"
require "openfeature/providers/*"

OpenFeature.provider = OpenFeature::Providers::InMemory.new
client = OpenFeature.client("app")

v2_enabled = client.boolean_value("v2_enabled", true)
v2_enabled.should eq(true)
```

The above code first sets the default provider. It then creates a client
that can be used to resolve feature flags, in this case it checks if
the **v2_enabled** is enabled.

## Contributing

1. Fork it (<https://github.com/threez/openfeature.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Vincent Landgraf](https://github.com/threez) - creator and maintainer

## API

* [OpenAPI specification](https://github.com/open-feature/protocol/blob/main/service/openapi.yaml)
* https://openfeature.dev/specification/
