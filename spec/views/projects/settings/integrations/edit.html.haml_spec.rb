# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/settings/integrations/edit', feature_category: :integrations do
  let(:project) { build_stubbed(:project) }
  let(:integration) { build_stubbed(:drone_ci_integration, project: project) }

  before do
    assign :project, project
    assign :integration, integration
  end

  it 'does not display recent events' do
    render

    expect(rendered).not_to have_text('Recent events')
  end

  context 'integration using WebHooks' do
    before do
      assign(:web_hook_logs, [])
    end

    it 'displays recent events' do
      render

      expect(rendered).to have_text('Recent events')
    end
  end
end
