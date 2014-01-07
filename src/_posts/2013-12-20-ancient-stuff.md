---
layout: post
title:  "Ancient Stuff"
date:   2013-12-30 16:19:50
tags: rails math
---

Jekyll also offers powerful support for code snippets:

### Directory structure

* **doggyloot/** - files for doggyloot templates to import into Sailthru
  * **images/** and **stylesheets/** - assets common to all templates
  * **templates/** - individual email templates and template-specific assets
    * **base.html** - an HTML skeleton for all templates
    * **[template_name]/** - a single template
      * **_includes/** - HTML snippets for this template
        * **_main.html** - the HTML for the body of this template
      * **images/** - images for this template
      * **stylesheets/[template_name].css** - CSS for this template
  * **_includes/** - HTML snippets for reuse in templates
* **ink-1.0.2/** - example templates using the [Ink](http://zurb.com/ink) responsive email framework (for reference)
* **sailthru-templates/** - email templates provided by Sailthru (for reference)

<!-- more -->

## Command-line tools

##### Dependencies

* Ruby 1.9.3 or later
* Rubygems
* Nokogiri (`gem install nokogiri`)
* HTTParty (`gem install httparty`)

##### new\_template.rb

This script sets up the file structure for a new template (see above).

Usage:

    ruby new_template receipt   # generates file structure for a "receipt" template

##### inline\_it.rb

This script will generate complete, inlined HTML using the **base.html** skeleton for the specified template names.

Usage:

    ruby inline_it.rb welcome           # generates inlined HTML for a template in the "welcome" folder
    ruby inline_it.rb welcome receipt   # generates inlined HTML for both the "welcome" and "receipt" templates
    ruby inline_it.rb                   # generates inlined HTML for all templates in doggyloot/templates/

This script does the following:

1. Builds the HTML for your template using whatever included HTML and CSS you specify (see "Using includes" below).
2. Inlines all CSS contained in `<style>` tags using the API for the [Ink Inliner](http://zurb.com/ink/inliner.php). There's more information about their API in [this wiki article](https://github.com/doggyloot/email-templates/wiki/Ink-Inliner-API-information).
3. Adds back some special CSS to the inlined HTML (see "CSS for inlined HTML" below).
4. Writes the resultant HTML to a file.

## Creating a new template

Run the `new_template.rb` script.

## Editing a template

The following steps would apply to a template called "welcome".

1. Add HTML for the template body to **doggyloot/templates/welcome/\_includes/\_main.html**. You need only add the HTML for the main content of the template, since the header, footer and styles will be generated automatically from **base.html**.
2. Upload any images specific to this template to the Sailthru Image Library and store them in **doggyloot/templates/welcome/images/**. Your HTML should reference only images stored in Sailthru, though.
3. Add any CSS necessary for this template to **doggyloot/templates/welcome/stylesheets/welcome.css**.
4. Run `ruby inline_it.rb welcome`, which will generate the HTML file **doggyloot/templates/welcome/welcome\.html**. This page can be tested in your browser.
5. Paste the inlined HTML into the corresponding template in the [Sailthru template editor](https://my.sailthru.com/templates). Test thouroughly using [Litmus](http://litmus.com).
6. Use the Text Version tab in the Sailthru template editor to automatically create a text version from the HTML.

#### Using includes

Any HTML files you create can include other HTML files using a declaration like the following (one per line):

    <!--#include_html _some_file.html-->
    
For instance, **base.html** contains `<!--#include_html _main.html-->`, which inserts the contents of **doggyloot/templates/welcome/\_includes/\_main.html** at that point in the HTML when you are generating the **welcome** template.

The **inline\_it.rb** script will look inside the specified template's **\_includes/** folder for a file called **\_some\_file.html** (e.g. **doggyloot/templates/welcome/\_includes/\_some\_file.html**), otherwise it will look inside **doggyloot/templates/\_includes/**.

You can use `include_html` statements inside other included files.

By convention, HTML that is common to multiple templates should be placed in **doggyloot/templates/\_includes/**, while included HTML for a specific template, like **\_main.html**, should be placed inside **doggyloot/templates/[template\_name]/\_includes/**. Since **inline\_it.rb** looks for HTML files inside the current template folder first, you can override included files in **doggyloot/templates/\_includes/** by having an identically named file in **doggyloot/templates/[template\_name]/\_includes/**.

#### CSS for inlined HTML

The Ink Inliner removes any CSS for which it can't find corresponding HTML elements. However, certain email clients will create HTML elements on-the-fly, like iOS's Mail app when it wraps auto-detected phone numbers and addresses with `<a>` tags. Per [Litmus](https://litmus.com/blog/update-banning-blue-links-on-ios-devices), you can wrap text you anticipate will be turned into links with a `<span class="whatever">` element and style it using regular CSS in a `<style>` tag. If you do not do this, these automatically-generated `<a>` tags will not receive your default link styles.

The CSS file **doggyloot/stylesheets/after_inlining.css** is where you should put styles for such HTML elements, since the contents of this file will be added after the HTML is inlined.

## Updating the base template

You might need to modify the general template/design for all transactional emails at once. For instance, changes to **base.html** or the **doggyloot.css** files will require that all templates be regenerated.

After making the necessary changes to the common HTML or CSS files, run **inline\_it.rb** with no arguments to generate inlined HTML for all templates present. You can then paste the resultant inlined HTML into Sailthru.

## TODO

* Guard integration
* Integrate Sailthru's API into the post-inlining process (instead of the current copy-paste step), provided there is a way to send new template HTML to them without updating the template that's active in production.
