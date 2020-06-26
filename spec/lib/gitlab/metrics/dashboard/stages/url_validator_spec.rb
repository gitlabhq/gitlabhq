# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::Stages::UrlValidator do
  let(:project) { build_stubbed(:project) }

  describe '#transform!' do
    context 'when the links contain a blocked url' do
      let(:dashboard) do
        {
          dashboard: "Test Dashboard",
          links: [
            { url: "http://1.1.1.1.1" },
            { url: "https://gitlab.com" },
            { url: "http://0.0.0.0" }
          ],
          panel_groups: [
            {
              group: "Group A",
              panels: [
                {
                  title: "Super Chart A1",
                  type: "area-chart",
                  y_label: "y_label",
                  metrics: [
                    {
                      id: "metric_a1",
                      query_range: "query",
                      unit: "unit",
                      label: "Legend Label"
                    }
                  ],
                  links: [
                    { url: "http://1.1.1.1.1" },
                    { url: "https://gitlab.com" },
                    { url: "http://0.0.0.0" }
                  ]
                }
              ]
            }
          ]
        }
      end

      let(:expected) do
        [{ url: '' }, { url: 'https://gitlab.com' }, { url: 'http://0.0.0.0' }]
      end

      let(:transform!) { described_class.new(project, dashboard, nil).transform! }

      before do
        stub_env('RSPEC_ALLOW_INVALID_URLS', 'false')
        stub_application_setting(allow_local_requests_from_web_hooks_and_services: true)
      end

      context 'dashboard related links' do
        it 'replaces the blocked url with an empty string' do
          transform!

          expect(dashboard[:links]).to eq(expected)
        end
      end

      context 'chart links' do
        it 'replaces the blocked url with an empty string' do
          transform!

          result = dashboard.dig(:panel_groups, 0, :panels, 0, :links)
          expect(result).to eq(expected)
        end
      end

      context 'when local requests are not allowed' do
        before do
          stub_application_setting(allow_local_requests_from_web_hooks_and_services: false)
        end

        let(:expected) do
          [{ url: '' }, { url: 'https://gitlab.com' }, { url: '' }]
        end

        it 'replaces the blocked url with an empty string' do
          transform!

          expect(dashboard[:links]).to eq(expected)
        end
      end

      context 'when the links are an array of strings instead of hashes' do
        before do
          dashboard[:links] = dashboard[:links].map(&:values)
        end

        it 'prevents an invalid link definition from erroring out' do
          expect { transform! }.not_to raise_error
        end
      end
    end
  end
end
