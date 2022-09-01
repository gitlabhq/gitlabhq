# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/web_hooks/_web_hook_disabled_alert' do
  let_it_be(:project) { create(:project) }

  let(:show_project_hook_failed_callout?) { false }

  def after_flash_content
    view.content_for(:after_flash_content)
  end

  before do
    assign(:project, project)
    allow(view).to receive(:show_project_hook_failed_callout?).and_return(show_project_hook_failed_callout?)
  end

  context 'when show_project_hook_failed_callout? is true' do
    let(:show_project_hook_failed_callout?) { true }

    it 'adds alert to `:after_flash_content`' do
      render

      expect(after_flash_content).to have_content('Webhook disabled')
    end
  end

  context 'when show_project_hook_failed_callout? is false' do
    it 'does not add alert to `:after_flash_content`' do
      # We have to use `view.render` because `render` causes issues
      # https://github.com/rails/rails/issues/41320
      view.render('shared/web_hooks/web_hook_disabled_alert')

      expect(after_flash_content).to be_nil
    end
  end
end
