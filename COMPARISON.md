# Comparisation

This guide is intended to help you understand the differences, strengths,
and tradeoffs when deciding which routing solution best fits your needs.

## Phoenix Router

Phoenix Router is the built‐in router provided by the Phoenix framework. Since
Phoenix 1.8 it offers simple path prefixing (e.g. using :path_prefixes for
language segments), but it does not support full URL translation.

**Stick to Phoenix Router if…**  
Your application has straightforward routing needs and you prefer to stick with
the built-in, battle-tested routing system without extra dependencies.

## Cldr Routes

Cldr Routes extends the Phoenix Router by adding support for URL translation.
Its tight coupling with the Cldr ecosystem ensures compatibility but that comes
at the cost of introducing a heavy dependency. While Cldr Routes handles
translated routes well, its feature set is focused mainly on
internationalization and does not offer much beyond that scope.

**Choose Cldr Routes if…**  
Your sole need is to support multilingual URLs and you are already invested in
the Cldr ecosystem.

## Routex

Routex takes routing in Phoenix to the next level. It is built as
[extension-driven](EXTENSION_SUMMARIES.md) middleware leveraging Phoenix Router
itself. Its extension-driven design means you get all the benefits of translated
routes—like those offered by Cldr Routes—plus a broader, more customizable set
of features that can be tailored to virtually any routing challenge.

Whether you need complete route translation, advanced route manipulation,
obfuscation, or alternative route generation, Routex provides a full suite of
tools without adding unnecessary runtime overhead or dependencies.

**Choose Routex if…**  
Routex is best if you foresee the need for extensive route transformations
(including translation), dynamic alternative routes, or if you want to avoid the
heavier dependencies imposed by Cldr Routes.

ps. If you invested in the Cldr ecosystem but need to use features only offered by Routex,
bridge the gap using [the Cldr extension for Routex](`Routex.Extension.Cldr`).


## Comparison table

| Feature             | Routex     | Cldr Routes         | Phoenix >= 1.8 |
|---------------------|------------|---------------------|----------------|
| Route encapsulation | Full  [^1] | Limited             | Limited        |
| Route manipulation  | Full  [^2] | Limited             | Limited        |
| Route interpolation | Full       | Limited             | Prefix only    |
| Alternative Routes  | Full       | Translation focused | Prefix only    |
| Verified Routes     | ☑          | ☑                   | ☑              |
| Translation         | ☑          | ☑                   | ☐              |
| Route Helpers       | ☑          | depr.               | depr.          |
| Drop-in replacement | ☑     [^3] | ☐                   | -              |
| Standalone          | ☑          | ☐                   | -              |
| Modular             | ☑          | ☐                   | -              |
| Extendable          | ☑          | ☐                   | -              |

[^1]: Routex' `preprocesss_using` is not bound to Phoenix (session) scopes  
[^2]: [Crazy example](https://hexdocs.pm/routex/Routex.Extension.Cloak.html)  
[^3]: *Optionally* Routex can be configured to shim original Phoenix functionality (for example: `~p` and `url/2`) or
mimick Cldr Routes using [an adapter extension](https://hexdocs.pm/routex/Routex.Extension.Cldr.html).
