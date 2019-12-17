# frozen_string_literal: true

require 'spec_helper'

describe 'projects/services/edit' do
  let(:service) { create(:drone_ci_service, project: project) }
  let(:project) { create(:project) }

  before do
    assign :project, project
    assign :service, service
  end

  it do
    render

    expect(rendered).not_to have_text('Recent Deliveries')
  end

  context 'service using WebHooks' do
    before do
      assign(:web_hook_logs, [])
    end

    it do
      render

      expect(rendered).to have_text('Recent Deliveries')
    end
  end
end
