# frozen_string_literal: true

module MetricsDashboardUrlHelpers
  # Using the url_helpers available in the test suite uses
  # the sample host, but the urls generated may need to
  # point to the configured host in the :js trait
  def urls
    ::Gitlab::Routing.url_helpers
  end

  def clear_host_from_memoized_variables
    [:metrics_regex, :grafana_regex, :clusters_regex, :alert_regex].each do |method_name|
      Gitlab::Metrics::Dashboard::Url.clear_memoization(method_name)
    end
  end

  def stub_gitlab_domain
    allow_any_instance_of(Banzai::Filter::InlineEmbedsFilter)
      .to receive(:gitlab_domain)
      .and_return(urls.root_url.chomp('/'))

    allow(Gitlab::Metrics::Dashboard::Url)
      .to receive(:gitlab_domain)
      .and_return(urls.root_url.chomp('/'))
  end
end
