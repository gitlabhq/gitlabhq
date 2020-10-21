# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::InlineGrafanaMetricsFilter do
  include FilterSpecHelper

  let_it_be(:project) { create(:project) }
  let_it_be(:grafana_integration) { create(:grafana_integration, project: project) }

  let(:input) { %(<a href="#{trigger_url}">example</a>) }
  let(:doc) { filter(input) }
  let(:embed_url) { doc.at_css('.js-render-metrics')['data-dashboard-url'] }

  let(:dashboard_path) do
    '/d/XDaNK6amz/gitlab-omnibus-redis' \
    '?from=1570397739557&panelId=14' \
    '&to=1570484139557&var-instance=All'
  end

  let(:trigger_url) { grafana_integration.grafana_url + dashboard_path }
  let(:dashboard_url) do
    urls.project_grafana_api_metrics_dashboard_url(
      project,
      grafana_url: trigger_url,
      embedded: true,
      start: "2019-10-06T21:35:39Z",
      end: "2019-10-07T21:35:39Z"
    )
  end

  it_behaves_like 'a metrics embed filter'

  around do |example|
    travel_to(Time.utc(2019, 3, 17, 13, 10)) { example.run }
  end

  context 'when grafana is not configured' do
    before do
      allow(project).to receive(:grafana_integration).and_return(nil)
    end

    it 'leaves the markdown unchanged' do
      expect(unescape(doc.to_s)).to eq(input)
    end
  end

  context 'when "panelId" parameter is missing' do
    let(:dashboard_path) { '/d/XDaNK6amz/gitlab-omnibus-redis?from=1570397739557&to=1570484139557' }

    it_behaves_like 'a metrics embed filter'
  end

  context 'when time window parameters are missing' do
    let(:dashboard_path) { '/d/XDaNK6amz/gitlab-omnibus-redis?panelId=16' }

    it 'sets the window to the last 8 hrs' do
      expect(embed_url).to include(
        'from%3D1552799400000', 'to%3D1552828200000',
        'start=2019-03-17T05%3A10%3A00Z', 'end=2019-03-17T13%3A10%3A00Z'
      )
    end
  end

  context 'when "to" parameter is missing' do
    let(:dashboard_path) { '/d/XDaNK6amz/gitlab-omnibus-redis?panelId=16&from=1570397739557' }

    it 'sets "to" to 8 hrs after "from"' do
      expect(embed_url).to include(
        'from%3D1570397739557', 'to%3D1570426539000',
        'start=2019-10-06T21%3A35%3A39Z', 'end=2019-10-07T05%3A35%3A39Z'
      )
    end
  end

  context 'when "from" parameter is missing' do
    let(:dashboard_path) { '/d/XDaNK6amz/gitlab-omnibus-redis?panelId=16&to=1570484139557' }

    it 'sets "from" to 8 hrs before "to"' do
      expect(embed_url).to include(
        'from%3D1570455339000', 'to%3D1570484139557',
        'start=2019-10-07T13%3A35%3A39Z', 'end=2019-10-07T21%3A35%3A39Z'
      )
    end
  end

  context 'when no parameters are provided' do
    let(:dashboard_path) { '/d/XDaNK6amz/gitlab-omnibus-redis' }

    it 'inserts a placeholder' do
      expect(embed_url).to be_present
    end
  end

  private

  # Nokogiri escapes the URLs, but we don't care about that
  # distinction for the purposes of this filter
  def unescape(html)
    CGI.unescapeHTML(html)
  end
end
