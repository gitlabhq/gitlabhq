# frozen_string_literal: true

# These contexts expect a `project` to be defined.
# It is expected that these contexts are used to create an
# alert.
RSpec.shared_context 'self-managed prometheus alert attributes' do
  let_it_be(:environment) { create(:environment, project: project, name: 'production') }

  let(:starts_at) { '2018-03-12T09:06:00Z' }
  let(:title) { 'title' }
  let(:y_label) { 'y_label' }
  let(:query) { 'avg(metric) > 1.0' }

  let(:embed_content) do
    {
      panel_groups: [{
        panels: [{
          type: 'area-chart',
          title: title,
          y_label: y_label,
          metrics: [{ query_range: query }]
        }]
      }]
    }.to_json
  end

  let(:payload) do
    {
      'startsAt' => starts_at,
      'generatorURL' => "http://host?g0.expr=#{CGI.escape(query)}",
      'labels' => {
        'gitlab_environment_name' => 'production'
      },
      'annotations' => {
        'title' => title,
        'gitlab_y_label' => y_label
      }
    }
  end
end
