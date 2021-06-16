# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanGrafanaUrl do
  let(:application_settings_table) { table(:application_settings) }

  [
    'javascript:alert(window.opener.document.location)',
    '  javascript:alert(window.opener.document.location)'
  ].each do |grafana_url|
    it "sets grafana_url back to its default value when grafana_url is '#{grafana_url}'" do
      application_settings = application_settings_table.create!(grafana_url: grafana_url)

      migrate!

      expect(application_settings.reload.grafana_url).to eq('/-/grafana')
    end
  end

  ['/-/grafana', '/some/relative/url', 'http://localhost:9000'].each do |grafana_url|
    it "does not modify grafana_url when grafana_url is '#{grafana_url}'" do
      application_settings = application_settings_table.create!(grafana_url: grafana_url)

      migrate!

      expect(application_settings.reload.grafana_url).to eq(grafana_url)
    end
  end

  context 'when application_settings table has no rows' do
    it 'does not fail' do
      migrate!
    end
  end
end
