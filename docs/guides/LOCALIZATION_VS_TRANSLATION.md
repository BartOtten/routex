# **Localization vs. Translation: Why Your Website Should Keep Them Separate**

When expanding a website for a global audience, businesses often confuse
**translation** with **localization**. While they are related, treating them as
the same process can lead to usability issues and a poor user experience.
Additionally, many websites make the mistake of assuming that a user's
**preferred language** matches their **physical location**, which can cause
frustration.

In this post, we’ll break down the differences between translation and
localization, why your website should separate them, and why **language
preferences should not be tied to a user's location**.


## The Problem: Conflating Location and Language

Many websites make the mistake of assuming that location dictates language.
While there's often a correlation, it's far from a perfect match. Think about
it:

* **Multilingual Regions:** Countries like Switzerland, Canada, and Belgium have
  multiple official languages. A user in Switzerland might prefer to browse in
  German, French, or Italian. Assuming their language based on their IP address
  (which indicates location) would be inaccurate.

* **Expatriates and Travelers:** Someone living abroad might prefer to browse in
  their native language, even if they're physically located in a different
  country. A German expat in Spain might still want to see the website in
  German.

* **Language Learning:** Some users might prefer to browse in a language they're
  learning, regardless of their location.

* **Shared Computers:** In internet cafes, libraries, or shared family
  computers, users might not have control over the browser's language settings.
  Relying on these settings can lead to an incorrect language selection.

**The Problem with `Accept-Language` HTTP Header:**

Websites often use the `Accept-Language` HTTP header, sent by the browser, to
determine the user's preferred language. While this can be helpful, it's not
foolproof. As mentioned above, on shared computers, the `Accept-Language` header
might reflect the preferences of a previous user. Users might also not know how
to change this setting, or it might be locked by system administrators in
certain environments. Therefore, relying solely on this header can lead to a
frustrating experience.

**Examples of What *Not* to Do:**

* **Automatic Redirection Based on IP:** A user in Canada is automatically
  redirected to the French version of the site, even though their browser and
  system language are set to English. This is a classic example of location
  overriding language preference.

* **Flag Icons as Language Options:** Using flag icons to represent language is
  problematic. Flags represent countries, not languages. What about Spanish
  speakers in the US? Or English speakers in India? This conflates nationality
  with language.

* **Hidden Language Settings:** Language options are buried deep in the footer
  or only appear after navigating through several pages. Users shouldn't have to
  hunt for their preferred language.

* **Sole Reliance on `Accept-Language`:** The website assumes the browser's
  language setting is the user's actual preference, ignoring the possibility of
  shared computers or incorrect settings.

## The Solution: Always Give Users Control

The key is to treat location and language as distinct, yet related, pieces of
information *and always give users explicit control over both*. Here's how to do
it right:

* **Explicit Language Selection:** Provide clear and prominent language options,
  ideally using the language name itself (e.g., "English," "Español," "Deutsch")
  rather than flags. Place these options in a visible location, such as the
  header or footer, *on every page*.

* **Location as a Secondary Consideration:** Use location data (IP address) to
  *suggest* a default language and/or currency, but *always* allow the user to
  override this suggestion. A simple popup or banner saying "We've detected
  you're in [Location]. Would you like to view the site in [Suggested Language]?
  [Yes/No]" is a good approach. Even if they click "yes," the language option
  should *still* be readily available.

* **User Profiles and Preferences:** For returning users, store their language
  and location preferences in their user profile. This ensures a consistent
  experience across sessions.

* **Content Localization, Not Just Translation:** Consider cultural nuances and
  adapt content accordingly. Simply translating text without considering
  cultural context can be ineffective or even offensive. Dates, times, and units
  of measurement should also be localized.

* **Clear Location Settings:** If location-specific content is crucial (e.g.,
  store locator, shipping information), provide a separate and easy-to-use
  location selection mechanism. This could be a dropdown menu or a map
  interface.

**Example of How to Do It Right:**

* A user lands on a website and sees a small popup: "We've detected you're in
  the UK. Would you like to view prices in GBP and the site in English?
  [Yes/No]"

* *Regardless* of the user's choice in the popup, a language dropdown menu is
  *always* visible in the header, offering options like "English," "Français,"
  "Español," etc.

* The footer contains a link to "Change Location," where the user can specify
  their country for location-specific content.

By implementing these best practices, websites can create a more inclusive and
user-friendly experience for their global audience. Respecting the distinction
between location and language, and *always giving users the control to choose*,
is not just good practice, it's essential for building trust and maximizing your
online reach.


## How Routex' approach helps

Routex's approach to localized routing reinforces the principle of keeping
language and location distinct. No implicit information is embedded in the
routes.

When dealing with **region-based pages** changing a user's region (and thus the
associated region-specific content) doesn't necessitate an automatic language
switch. And when dealing with **language-based pages** changing a user's
language doesn't necessitate an automatic region switch.

Imagine a scenario where a user is browsing a **region-based** site in English
but wants to see the pricing and product availability for the Indian market.
With Routex, they can navigate to the India region-specific page (e.g.,
/in/products) without being forced to switch to another language. The site can
maintain the user's preferred language (English in this case) while displaying
the relevant Indian content.

This is in stark contrast to systems where language and region are implicitly
linked. In such cases, switching regions might inadvertently trigger a language
change, leading to a confusing and frustrating user experience.


## **Conclusion**

Localization and translation serve different purposes and should be handled
separately to provide the best user experience. Similarly, **a user's preferred
language should not be assumed based on their location**. By keeping these
elements distinct, websites can ensure better usability, compliance, and
engagement for a global audience.

By adopting **a user-first approach**, where language is a choice and location
is used only for relevant regional settings, businesses can create a seamless,
accessible, and culturally appropriate experience for all users.
