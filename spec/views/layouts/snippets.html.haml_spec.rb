# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/snippets', feature_category: :snippets do
  before do
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:current_user_mode).and_return(Gitlab::Auth::CurrentUserMode.new(user))
  end

  describe 'sidebar' do
    context 'when feature flag is on' do
      context 'when signed in' do
        let(:user) { build_stubbed(:user) }

        it 'renders the "Your work" sidebar' do
          render

          expect(rendered).to have_css('aside.nav-sidebar[aria-label="Your work"]')
        end
      end

      context 'when not signed in' do
        let(:user) { nil }

        it 'renders no sidebar' do
          render

          expect(rendered).not_to have_css('aside.nav-sidebar')
        end
      end
    end

    context 'when feature flag is off' do
      before do
        stub_feature_flags(your_work_sidebar: false)
      end

      let(:user) { build_stubbed(:user) }

      it 'renders no sidebar' do
        render

        expect(rendered).not_to have_css('aside.nav-sidebar')
      end
    end
  end
end
