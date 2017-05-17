require 'spec_helper'

describe 'admin/conversational_development_index_metrics/show.html.haml' do
  before do
    stub_template 'admin/conversational_development_index_metrics/_disabled.html.haml' => 'convdev disabled'
    stub_template 'admin/conversational_development_index_metrics/_no_data.html.haml' => 'convdev no data'
    stub_template 'admin/conversational_development_index_metrics/_card.html.haml' => 'convdev card'
  end

  context 'when usage ping is disabled' do
    it 'shows empty state' do
      allow(current_application_settings).to receive(:usage_ping_enabled) { false }

      render

      expect(rendered).to have_content 'convdev disabled'
    end
  end

  context 'no usage data' do
    it 'shows empty state' do
      allow(@conversational_development_index_metric).to receive(:blank?) { true }

      render

      expect(rendered).to have_content 'convdev no data'
    end
  end

  it 'renders cards' do
    assign(:cards, [{name: 'test'}])
    assign(:conversational_development_index_metric, ['test',])

    render

    expect(rendered).to have_content 'convdev card'
  end
end
