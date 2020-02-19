# frozen_string_literal: true

require 'spec_helper'

describe Banzai::Filter::InlineGrafanaMetricsFilter do
  include FilterSpecHelper

  let_it_be(:project) { create(:project) }
  let_it_be(:grafana_integration) { create(:grafana_integration, project: project) }

  let(:input) { %(<a href="#{trigger_url}">example</a>) }
  let(:doc) { filter(input) }
  let(:dashboard_path) do
    '/d/XDaNK6amz/gitlab-omnibus-redis' \
    '?from=1570397739557&to=1570484139557' \
    '&var-instance=All&panelId=14'
  end

  let(:trigger_url) { grafana_integration.grafana_url + dashboard_path }
  let(:dashboard_url) do
    urls.project_grafana_api_metrics_dashboard_url(
      project,
      embedded: true,
      grafana_url: trigger_url,
      start: "2019-10-06T21:35:39Z",
      end: "2019-10-07T21:35:39Z"
    )
  end

  it_behaves_like 'a metrics embed filter'

  context 'when grafana is not configured' do
    before do
      allow(project).to receive(:grafana_integration).and_return(nil)
    end

    it 'leaves the markdown unchanged' do
      expect(unescape(doc.to_s)).to eq(input)
    end
  end

  context 'when parameters are missing' do
    let(:dashboard_path) { '/d/XDaNK6amz/gitlab-omnibus-redis' }

    it 'leaves the markdown unchanged' do
      expect(unescape(doc.to_s)).to eq(input)
    end
  end

  private

  # Nokogiri escapes the URLs, but we don't care about that
  # distinction for the purposes of this filter
  def unescape(html)
    CGI.unescapeHTML(html)
  end
end
