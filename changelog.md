# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](Https://conventionalcommits.org) for commit guidelines.

<!-- changelog -->

## [v1.3.2](https://github.com/BartOtten/routex/compare/v1.3.1...v1.3.2) (2026-01-27)

### Bug Fixes:

* core: matchable type warning in Elixir 1.20+ (#123) by rubas

### Soft Deprecation:

#### refactor(core): Routex.Branching overhaul

This change is (only) significant for extension developers. Parameter were
reordered and some option have been renamed (the old names are soft deprecated).
Please migrate your extensions when seeing deprecation messages.

IMPROVED:
- Simplified transformer option format for better ergonomics
- Comprehensive documentation with additional real-world examples
- Clearer naming conventions across the API
- Better type specifications and parameter descriptions
- Extended tests

SOFT DEPRECATIONS:
- Transformer return value `:skip` is deprecated in favor of `:noop` for clarity
- New parameters order for improved cognitive flow (old order soft deprecated)
- Options have been renamed for clarity:

    * :as -> :name_branched
    * :orig -> :name_passthrough
    * :arg_pos -> :param_position

MIGRATION GUIDE:

- Rename options (see above):
    Routex.Branching.branch_macro(... , param_position: fn arity -> arity - 1 end)

- Replace `:skip` with `:noop` in transformer functions:
    ```elixir
    def my_transformer(pattern, arg) do
      if should_skip?(pattern), do: :noop, else: arg
    end
    ```

- Replace MFA transformer options with the new format, the value of extra arguments should
be put in the transformer functions themselves:

````
old:
*_transformer: {__MODULE__.Transformers, :transform_arg, [:foo]}

new:
*_transformer: &__MODULE__.Transformers.transform_clause/2

def my_transformer(pattern, arg) do
  arg <> to_string(:foo)
end
````


## [v1.3.1](https://github.com/BartOtten/routex/compare/v1.3.0...v1.3.1) (2025-11-12)




## [v1.3.0](https://github.com/BartOtten/routex/compare/v1.3.0-rc.3...v1.3.0) (2025-11-10)




### Features:

* add callback create_shared_helpers/3 by Bart Otten

* cloak: custom functions for route transformation by Bart Otten

* utils: add helper to set rtx_branch in process dict by Bart Otten

* derive branch from url assignment by Bart Otten

### Bug Fixes:

* verified: undefined sigil_p when no routes are wrapped by Bart Otten

* locale: compilation issues when locale module is auto detected by Bart Otten

## [1.3.0-rc.3](https://github.com/BartOtten/routex/compare/v1.3.0-rc.1...1.3.0-rc.3) (2025-11-10)




### Bug Fixes:

* verified: undefined sigil_p when no routes are wrapped by Bart Otten

* locale: compilation issues when locale module is auto detected by Bart Otten

## [v1.3.0-rc.1](https://github.com/BartOtten/routex/compare/v1.3.0-rc.0...v1.3.0-rc.1) (2025-09-29)




### Bug Fixes:

* core: no matching function clause due to newline metadata.

## [v1.3.0-rc.0](https://github.com/BartOtten/routex/compare/v1.2.4...v1.3.0-rc.0) (2025-09-24)




### Features:

* implement routex.install task

### Bug Fixes:

* mermaid loaded unnecessary

* update default config to match USAGE guide

* igniter installer fails to update Web module

## [v1.2.4](https://github.com/BartOtten/routex/compare/v1.2.3...v1.2.4) (2025-09-06)




### Bug Fixes:

* plug: use URI.parse to support list query params with brackets

## [v1.2.3](https://github.com/BartOtten/routex/compare/v1.2.2...v1.2.3) (2025-09-05)




### Bug Fixes:

* plug pipeline broken for non-routex routes

## [v1.2.2](https://github.com/BartOtten/routex/compare/v1.2.1...v1.2.2) (2025-05-06)




### Bug Fixes:

* processing: order not fully restored

## [v1.2.1](https://github.com/BartOtten/routex/compare/v1.2.0...v1.2.1) (2025-05-05)




### Bug Fixes:

* core: reduction error when all routes are wrapped

* localize: custom route prefix ignored
## [v1.2.0](https://github.com/BartOtten/routex/compare/v1.1.0...v1.2.0) (2025-05-01)

### New Extensions:

* `Routex.Extension.Localize.Phoenix.Routes` - compile time localization

* `Routex.Extension.Localize.Phoenix.Runtime` - runtime localization

* `Routex.Extension.RuntimeDispatcher` - set state / put locale using route attributes

* `Routex.Extension.LiveViewHooks` - inlines custom LiveView lifecycle hooks provided by other extensions

* `Routex.Extension.Plugs` - detects and inlines custom Plugs provided by other extensions

### Features

* auto detection and usage of existing Cldr, Gettext or Fluent setup.

* support `locales` and `default_locale` for auto generated localized routes

* support attribute overrides for `locale` attributes

* `Routex.Extension.Localize.Registry` - simple locale registry based on IANA

* clear error messages when extensions are missing

* show summary of processed routes

* new config option to inspect generated helpers code


### Docs

* simplified Usage guide

* improved Localization guide

* updated Comparison guide


### Bug Fixes:

* core: warnings generated by mix docs

* core: compilation failure due to uncompiled backends

* core: compilation lockups / delays


### Tests:

* reached > 90% test coverage

* enforce > 90% test coverage



## [v1.1.0](https://github.com/BartOtten/routex/compare/v1.0.0...v1.1.0) (2025-02-13)


### Features:

* provide assigns directly in conn

* core: add function to print critical messages

### Bug Fixes:

* match patterns fail on trailing slash

* undefined on_mount/4, silent missing attrs/1




## [v1.0.0](https://github.com/BartOtten/routex/compare/v0.3.0-alpha.4...v1.0.0) (2025-02-03)


### Features:

* support Phoenix Liveview >= 1.0

### Bug Fixes:

* ci: upgrade artifact actions in workflow

* core: comp. error - cannot set :__struct__ in struct definition

* incorrect typespecs

* cldr: use territory_from_locale for territory resolution


## v0.x

The CHANGELOG for v0.x releases can be found in the [v0.x branch](https://github.com/BartOtten/routex/blob/v0.x/CHANGELOG.md).
