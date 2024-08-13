# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/hooks/edit' do
  let(:hook) { create(:project_hook, project: project) }

  let_it_be_with_refind(:project) { create(:project) }

  before do
    assign :project, project
    assign :hook, hook
  end

  it 'renders webhook page with "Recent events"' do
    render

    expect(rendered).to have_css('.gl-heading-2', text: _('Webhook'))
    expect(rendered).to have_text(_('Recent events'))
  end

  context 'webhook is rate limited' do
    before do
      allow(hook).to receive(:rate_limited?).and_return(true)
    end

    it 'renders alert' do
      render

      expect(rendered).to have_text(s_('Webhooks|Webhook rate limit has been reached'))
    end
  end

  context 'webhook is permanently disabled' do
    before do
      allow(hook).to receive(:permanently_disabled?).and_return(true)
    end

    it 'renders alert' do
      render

      expect(rendered).to have_text(s_('Webhooks|Webhook failed to connect'))
    end
  end

  context 'webhook is temporarily disabled' do
    before do
      allow(hook).to receive(:temporarily_disabled?).and_return(true)
      allow(hook).to receive(:disabled_until).and_return(Time.now + 10.minutes)
    end

    it 'renders alert' do
      render

      expect(rendered).to have_text(s_('Webhooks|Webhook fails to connect'))
    end
  end
end
