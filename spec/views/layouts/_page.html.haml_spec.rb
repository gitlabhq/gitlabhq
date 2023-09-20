# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/_page', feature_category: :geo_replication do
  let_it_be(:user) { build_stubbed(:user) }

  describe '_silent_mode_banner' do
    before do
      allow(view).to receive(:current_user).and_return(user)
      allow(view).to receive(:current_user_mode).and_return(Gitlab::Auth::CurrentUserMode.new(user))
    end

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
end
