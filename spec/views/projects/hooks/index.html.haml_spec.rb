# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/hooks/index' do
  let(:existing_hook) { create(:project_hook, project: project) }
  let(:new_hook) { ProjectHook.new }

  let_it_be_with_refind(:project) { create(:project) }

  before do
    assign :project, project
    assign :hooks, [existing_hook]
    assign :hook, new_hook
  end

  it 'renders webhooks page with "Webhooks"' do
    render

    expect(rendered).to have_css('.gl-heading-2', text: _('Webhooks'))
    expect(rendered).to have_text('Webhooks')
    expect(rendered).not_to have_css('.gl-badge', text: _('Disabled'))
    expect(rendered).not_to have_css('.gl-badge', text: s_('Webhooks|Failed to connect'))
    expect(rendered).not_to have_css('.gl-badge', text: s_('Webhooks|Fails to connect'))
  end

  context 'webhook is rate limited' do
    before do
      allow(existing_hook).to receive(:rate_limited?).and_return(true)
    end

    it 'renders "Disabled" badge' do
      render

      expect(rendered).to have_css('.gl-badge', text: _('Disabled'))
    end
  end

  context 'webhook is permanently disabled' do
    before do
      allow(existing_hook).to receive(:permanently_disabled?).and_return(true)
    end

    it 'renders "Failed to connect" badge' do
      render

      expect(rendered).to have_css('.gl-badge', text: s_('Webhooks|Failed to connect'))
    end
  end

  context 'webhook is temporarily disabled' do
    before do
      allow(existing_hook).to receive(:temporarily_disabled?).and_return(true)
    end

    it 'renders "Fails to connect" badge' do
      render

      expect(rendered).to have_css('.gl-badge', text: s_('Webhooks|Fails to connect'))
    end
  end
end
