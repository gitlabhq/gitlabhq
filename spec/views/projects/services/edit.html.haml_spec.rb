# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/services/edit' do
  let(:integration) { create(:drone_ci_integration, project: project) }
  let(:project) { create(:project) }

  before do
    assign :project, project
    assign :integration, integration
  end

  it do
    render

    expect(rendered).not_to have_text('Recent Deliveries')
  end

  context 'integration using WebHooks' do
    before do
      assign(:web_hook_logs, [])
    end

    it do
      render

      expect(rendered).to have_text('Recent Deliveries')
    end
  end
end
