# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](Https://conventionalcommits.org) for commit guidelines.

<!-- changelog -->

## [v0.3.0-alpha.2](https://github.com/BartOtten/routex/compare/v0.3.0-alpha.1...v0.3.0-alpha.2) (2024-10-23)
### Breaking Changes:

* dev: rename development aid functions

* alternatives: rename :is_current? to :match?

* translations: depend on Gettext greater than 0.26.0



### Bug Fixes:

* docs: warnings about referencing Phoenix.Router.Route

* core: rename is_private/1 to private?/1

* ci: update Github actions

* core: warning during compilation about usage of :warn

## [v0.3.0-alpha.1](https://github.com/BartOtten/routex/compare/v0.3.0-alpha.1...v0.3.0-alpha.1) (2024-10-21)
### Breaking Changes:

* core: remove Routex.Path module

* core: split Extension Utils module

* alternatives: rename scope to branch



### Features:

* core: merge private Routex attrs into socket

* verified: branching macro's of all arities of ~p, url and path

* core: enable AST-free manipulation of routes with interpolation

* alternatives: indicate if an alternative route `is_current?`

* interpol: add extension for interpolation of routes

* translations: distinct locale and language

* core: introduce Branching module

* core: introduce Matchable module

## [v0.2.0-alpha.8](https://github.com/BartOtten/routex/compare/v0.2.0-alpha.7...v0.2.0-alpha.8) (2023-10-18)




### Bug Fixes:

* translations: reliably extract segments to translate

## [v0.2.0-alpha.7](https://github.com/BartOtten/routex/compare/v0.1.0-alpha.7...v0.2.0-alpha.7) (2023-05-31)




### Features:

* utils: use verbose defaults for esc_inspect/2

### Bug Fixes:

* route: swallowed routes due to nonunique map key

## [v0.1.0-alpha.6](https://github.com/BartOtten/routex/compare/v0.1.0-alpha.5...v0.1.0-alpha.6) (2023-05-30)




## [v0.1.0-alpha.5](https://github.com/BartOtten/routex/compare/v0.1.0-alpha.5...v0.1.0-alpha.5) (2023-05-05)




### Features:

* add ROUTEX_DEBUG for compilation debugging (#3)

### Bug Fixes:

* verified: let Phoenix handle missing routes
