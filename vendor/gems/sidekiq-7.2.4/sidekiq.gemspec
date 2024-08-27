require_relative "lib/sidekiq/version"

Gem::Specification.new do |gem|
  gem.authors = ["Mike Perham"]
  gem.email = ["info@contribsys.com"]
  gem.summary = "Simple, efficient background processing for Ruby"
  gem.description = "Simple, efficient background processing for Ruby."
  gem.homepage = "https://sidekiq.org"
  gem.license = "LGPL-3.0"

  gem.executables = ["sidekiq", "sidekiqmon"]
  gem.files = %w[
    sidekiq.gemspec
    README.md
    Changes.md
    LICENSE.txt
    bin/multi_queue_bench
    bin/sidekiq
    bin/sidekiqload
    bin/sidekiqmon
    lib/generators/sidekiq/job_generator.rb
    lib/generators/sidekiq/templates/job.rb.erb
    lib/generators/sidekiq/templates/job_spec.rb.erb
    lib/generators/sidekiq/templates/job_test.rb.erb
    lib/sidekiq.rb
    lib/sidekiq/api.rb
    lib/sidekiq/capsule.rb
    lib/sidekiq/cli.rb
    lib/sidekiq/client.rb
    lib/sidekiq/component.rb
    lib/sidekiq/config.rb
    lib/sidekiq/deploy.rb
    lib/sidekiq/embedded.rb
    lib/sidekiq/fetch.rb
    lib/sidekiq/job.rb
    lib/sidekiq/job_logger.rb
    lib/sidekiq/job_retry.rb
    lib/sidekiq/job_util.rb
    lib/sidekiq/launcher.rb
    lib/sidekiq/logger.rb
    lib/sidekiq/manager.rb
    lib/sidekiq/metrics/query.rb
    lib/sidekiq/metrics/shared.rb
    lib/sidekiq/metrics/tracking.rb
    lib/sidekiq/middleware/chain.rb
    lib/sidekiq/middleware/current_attributes.rb
    lib/sidekiq/middleware/i18n.rb
    lib/sidekiq/middleware/modules.rb
    lib/sidekiq/monitor.rb
    lib/sidekiq/paginator.rb
    lib/sidekiq/processor.rb
    lib/sidekiq/rails.rb
    lib/sidekiq/redis_client_adapter.rb
    lib/sidekiq/redis_connection.rb
    lib/sidekiq/ring_buffer.rb
    lib/sidekiq/scheduled.rb
    lib/sidekiq/sd_notify.rb
    lib/sidekiq/systemd.rb
    lib/sidekiq/testing.rb
    lib/sidekiq/testing/inline.rb
    lib/sidekiq/transaction_aware_client.rb
    lib/sidekiq/version.rb
    lib/sidekiq/web.rb
    lib/sidekiq/web/action.rb
    lib/sidekiq/web/application.rb
    lib/sidekiq/web/csrf_protection.rb
    lib/sidekiq/web/helpers.rb
    lib/sidekiq/web/router.rb
    lib/sidekiq/worker_compatibility_alias.rb
    web/assets/images/apple-touch-icon.png
    web/assets/images/favicon.ico
    web/assets/images/logo.png
    web/assets/images/status.png
    web/assets/javascripts/application.js
    web/assets/javascripts/base-charts.js
    web/assets/javascripts/chart.min.js
    web/assets/javascripts/chartjs-plugin-annotation.min.js
    web/assets/javascripts/dashboard-charts.js
    web/assets/javascripts/dashboard.js
    web/assets/javascripts/metrics.js
    web/assets/stylesheets/application-dark.css
    web/assets/stylesheets/application-rtl.css
    web/assets/stylesheets/application.css
    web/assets/stylesheets/bootstrap-rtl.min.css
    web/assets/stylesheets/bootstrap.css
    web/locales/ar.yml
    web/locales/cs.yml
    web/locales/da.yml
    web/locales/de.yml
    web/locales/el.yml
    web/locales/en.yml
    web/locales/es.yml
    web/locales/fa.yml
    web/locales/fr.yml
    web/locales/gd.yml
    web/locales/he.yml
    web/locales/hi.yml
    web/locales/it.yml
    web/locales/ja.yml
    web/locales/ko.yml
    web/locales/lt.yml
    web/locales/nb.yml
    web/locales/nl.yml
    web/locales/pl.yml
    web/locales/pt-br.yml
    web/locales/pt.yml
    web/locales/ru.yml
    web/locales/sv.yml
    web/locales/ta.yml
    web/locales/uk.yml
    web/locales/ur.yml
    web/locales/vi.yml
    web/locales/zh-cn.yml
    web/locales/zh-tw.yml
    web/views/_footer.erb
    web/views/_job_info.erb
    web/views/_metrics_period_select.erb
    web/views/_nav.erb
    web/views/_paging.erb
    web/views/_poll_link.erb
    web/views/_status.erb
    web/views/_summary.erb
    web/views/busy.erb
    web/views/dashboard.erb
    web/views/dead.erb
    web/views/filtering.erb
    web/views/layout.erb
    web/views/metrics.erb
    web/views/metrics_for_job.erb
    web/views/morgue.erb
    web/views/queue.erb
    web/views/queues.erb
    web/views/retries.erb
    web/views/retry.erb
    web/views/scheduled.erb
    web/views/scheduled_job_info.erb
  ]
  gem.name = "sidekiq"
  gem.version = Sidekiq::VERSION
  gem.required_ruby_version = ">= 2.7.0"

  gem.metadata = {
    "homepage_uri" => "https://sidekiq.org",
    "bug_tracker_uri" => "https://github.com/sidekiq/sidekiq/issues",
    "documentation_uri" => "https://github.com/sidekiq/sidekiq/wiki",
    "changelog_uri" => "https://github.com/sidekiq/sidekiq/blob/main/Changes.md",
    "source_code_uri" => "https://github.com/sidekiq/sidekiq",
    "rubygems_mfa_required" => "true"
  }

  gem.add_dependency "redis-client", ">= 0.19.0"
  gem.add_dependency "connection_pool", ">= 2.3.0"
  gem.add_dependency "rack", ">= 2.2.4"
  gem.add_dependency "concurrent-ruby", "< 2"
end
