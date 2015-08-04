Teaspoon.configure do |config|
  # Determines where the Teaspoon routes will be mounted. Changing this to "/jasmine" would allow you to browse to
  # `http://localhost:3000/jasmine` to run your tests.
  config.mount_at = "/teaspoon"

  # Specifies the root where Teaspoon will look for files. If you're testing an engine using a dummy application it can
  # be useful to set this to your engines root (e.g. `Teaspoon::Engine.root`).
  # Note: Defaults to `Rails.root` if nil.
  config.root = nil

  # Paths that will be appended to the Rails assets paths
  # Note: Relative to `config.root`.
  config.asset_paths = ["spec/javascripts", "spec/javascripts/stylesheets"]

  # Fixtures are rendered through a controller, which allows using HAML, RABL/JBuilder, etc. Files in these paths will
  # be rendered as fixtures.
  config.fixture_paths = ["spec/javascripts/fixtures"]

  # SUITES
  #
  # You can modify the default suite configuration and create new suites here. Suites are isolated from one another.
  #
  # When defining a suite you can provide a name and a block. If the name is left blank, :default is assumed. You can
  # omit various directives and the ones defined in the default suite will be used.
  #
  # To run a specific suite
  # - in the browser: http://localhost/teaspoon/[suite_name]
  # - with the rake task: rake teaspoon suite=[suite_name]
  # - with the cli: teaspoon --suite=[suite_name]
  config.suite do |suite|
    # Specify the framework you would like to use. This allows you to select versions, and will do some basic setup for
    # you -- which you can override with the directives below. This should be specified first, as it can override other
    # directives.
    # Note: If no version is specified, the latest is assumed.
    #
    # Versions: 1.3.1, 2.0.3, 2.1.3, 2.2.0
    suite.use_framework :jasmine, "2.2.0"

    # Specify a file matcher as a regular expression and all matching files will be loaded when the suite is run. These
    # files need to be within an asset path. You can add asset paths using the `config.asset_paths`.
    suite.matcher = "{spec/javascripts,app/assets}/**/*_spec.{js,js.coffee,coffee}"

    # Load additional JS files, but requiring them in your spec helper is the preferred way to do this.
    #suite.javascripts = []

    # You can include your own stylesheets if you want to change how Teaspoon looks.
    # Note: Spec related CSS can and should be loaded using fixtures.
    #suite.stylesheets = ["teaspoon"]

    # This suites spec helper, which can require additional support files. This file is loaded before any of your test
    # files are loaded.
    suite.helper = "spec_helper"

    # Partial to be rendered in the head tag of the runner. You can use the provided ones or define your own by creating
    # a `_boot.html.erb` in your fixtures path, and adjust the config to `"/boot"` for instance.
    #
    # Available: boot, boot_require_js
    suite.boot_partial = "boot"

    # Partial to be rendered in the body tag of the runner. You can define your own to create a custom body structure.
    suite.body_partial = "body"

    # Hooks allow you to use `Teaspoon.hook("fixtures")` before, after, or during your spec run. This will make a
    # synchronous Ajax request to the server that will call all of the blocks you've defined for that hook name.
    #suite.hook :fixtures, &proc{}

    # Determine whether specs loaded into the test harness should be embedded as individual script tags or concatenated
    # into a single file. Similar to Rails' asset `debug: true` and `config.assets.debug = true` options. By default, 
    # Teaspoon expands all assets to provide more valuable stack traces that reference individual source files.
    #suite.expand_assets = true
  end

  # Example suite. Since we're just filtering to files already within the root test/javascripts, these files will also
  # be run in the default suite -- but can be focused into a more specific suite.
  #config.suite :targeted do |suite|
  #  suite.matcher = "spec/javascripts/targeted/*_spec.{js,js.coffee,coffee}"
  #end

  # CONSOLE RUNNER SPECIFIC
  #
  # These configuration directives are applicable only when running via the rake task or command line interface. These
  # directives can be overridden using the command line interface arguments or with ENV variables when using the rake
  # task.
  #
  # Command Line Interface:
  # teaspoon --driver=phantomjs --server-port=31337 --fail-fast=true --format=junit --suite=my_suite /spec/file_spec.js
  #
  # Rake:
  # teaspoon DRIVER=phantomjs SERVER_PORT=31337 FAIL_FAST=true FORMATTERS=junit suite=my_suite

  # Specify which headless driver to use. Supports PhantomJS and Selenium Webdriver.
  #
  # Available: :phantomjs, :selenium, :capybara_webkit
  # PhantomJS: https://github.com/modeset/teaspoon/wiki/Using-PhantomJS
  # Selenium Webdriver: https://github.com/modeset/teaspoon/wiki/Using-Selenium-WebDriver
  # Capybara Webkit: https://github.com/modeset/teaspoon/wiki/Using-Capybara-Webkit
  #config.driver = :phantomjs

  # Specify additional options for the driver.
  #
  # PhantomJS: https://github.com/modeset/teaspoon/wiki/Using-PhantomJS
  # Selenium Webdriver: https://github.com/modeset/teaspoon/wiki/Using-Selenium-WebDriver
  # Capybara Webkit: https://github.com/modeset/teaspoon/wiki/Using-Capybara-Webkit
  #config.driver_options = nil

  # Specify the timeout for the driver. Specs are expected to complete within this time frame or the run will be
  # considered a failure. This is to avoid issues that can arise where tests stall.
  #config.driver_timeout = 180

  # Specify a server to use with Rack (e.g. thin, mongrel). If nil is provided Rack::Server is used.
  #config.server = nil

  # Specify a port to run on a specific port, otherwise Teaspoon will use a random available port.
  #config.server_port = nil

  # Timeout for starting the server in seconds. If your server is slow to start you may have to bump this, or you may
  # want to lower this if you know it shouldn't take long to start.
  #config.server_timeout = 20

  # Force Teaspoon to fail immediately after a failing suite. Can be useful to make Teaspoon fail early if you have
  # several suites, but in environments like CI this may not be desirable.
  #config.fail_fast = true

  # Specify the formatters to use when outputting the results.
  # Note: Output files can be specified by using `"junit>/path/to/output.xml"`.
  #
  # Available: :dot, :clean, :documentation, :json, :junit, :pride, :rspec_html, :snowday, :swayze_or_oprah, :tap, :tap_y, :teamcity
  #config.formatters = [:dot]

  # Specify if you want color output from the formatters.
  #config.color = true

  # Teaspoon pipes all console[log/debug/error] to $stdout. This is useful to catch places where you've forgotten to
  # remove them, but in verbose applications this may not be desirable.
  #config.suppress_log = false

  # COVERAGE REPORTS / THRESHOLD ASSERTIONS
  #
  # Coverage reports requires Istanbul (https://github.com/gotwarlost/istanbul) to add instrumentation to your code and
  # display coverage statistics.
  #
  # Coverage configurations are similar to suites. You can define several, and use different ones under different
  # conditions.
  #
  # To run with a specific coverage configuration
  # - with the rake task: rake teaspoon USE_COVERAGE=[coverage_name]
  # - with the cli: teaspoon --coverage=[coverage_name]

  # Specify that you always want a coverage configuration to be used. Otherwise, specify that you want coverage
  # on the CLI.
  # Set this to "true" or the name of your coverage config.
  #config.use_coverage = nil

  # You can have multiple coverage configs by passing a name to config.coverage.
  # e.g. config.coverage :ci do |coverage|
  # The default coverage config name is :default.
  config.coverage do |coverage|
    # Which coverage reports Istanbul should generate. Correlates directly to what Istanbul supports.
    #
    # Available: text-summary, text, html, lcov, lcovonly, cobertura, teamcity
    #coverage.reports = ["text-summary", "html"]

    # The path that the coverage should be written to - when there's an artifact to write to disk.
    # Note: Relative to `config.root`.
    #coverage.output_path = "coverage"

    # Assets to be ignored when generating coverage reports. Accepts an array of filenames or regular expressions. The
    # default excludes assets from vendor, gems and support libraries.
    #coverage.ignore = [%r{/lib/ruby/gems/}, %r{/vendor/assets/}, %r{/support/}, %r{/(.+)_helper.}]

    # Various thresholds requirements can be defined, and those thresholds will be checked at the end of a run. If any
    # aren't met the run will fail with a message. Thresholds can be defined as a percentage (0-100), or nil.
    #coverage.statements = nil
    #coverage.functions = nil
    #coverage.branches = nil
    #coverage.lines = nil
  end
end
