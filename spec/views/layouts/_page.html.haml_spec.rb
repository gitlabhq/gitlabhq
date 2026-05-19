# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/_page', feature_category: :geo_replication do
  let(:user) { build_stubbed(:user) }

  before do
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:current_user_mode).and_return(Gitlab::Auth::CurrentUserMode.new(user))
  end

  describe '_silent_mode_banner' do
    describe 'when ::Gitlab::SilentMode.enabled? is true' do
      before do
        allow(::Gitlab::SilentMode).to receive(:enabled?).and_return(true)
      end

      it 'renders silent mode banner' do
        render

        expect(rendered).to have_text('Silent mode is enabled')
      end
    end

    describe 'when ::Gitlab::SilentMode.enabled? is false' do
      before do
        allow(::Gitlab::SilentMode).to receive(:enabled?).and_return(false)
      end

      it 'does not silent mode banner' do
        render

        expect(rendered).not_to have_text('Silent mode is enabled')
      end
    end
  end

  describe '@force_show_panel_header' do
    before do
      stub_feature_flags(page_breadcrumbs_in_top_bar: true)
    end

    context 'when @force_show_panel_header is not set' do
      it 'applies without-breadcrumbs to the panel header' do
        render

        expect(rendered).to have_css('.panel-header-inner.without-breadcrumbs')
      end
    end

    context 'when @force_show_panel_header is true' do
      before do
        assign(:force_show_panel_header, true)
      end

      it 'does not apply without-breadcrumbs to the panel header' do
        render

        expect(rendered).not_to have_css('.panel-header-inner.without-breadcrumbs')
      end
    end
  end

  describe 'static_panel_actions content_for' do
    it 'yields :static_panel_actions content into the actions area' do
      view.content_for(:static_panel_actions) { tag.button { 'Test action' } }

      render

      expect(rendered).to have_button('Test action')
    end
  end

  describe '_broadcast' do
    context 'when broadcast messages are hidden' do
      before do
        view.content_for(:hide_broadcast_messages, true)
      end

      it 'does not render broadcast messages' do
        render

        expect(rendered).not_to render_template('layouts/_broadcast')
      end
    end

    context 'when `:hide_broadcast_messages` is not present' do
      it 'renders broadcast messages' do
        render

        expect(rendered).to render_template('layouts/_broadcast')
      end
    end
  end
end
