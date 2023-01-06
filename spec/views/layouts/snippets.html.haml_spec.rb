# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/snippets', feature_category: :snippets do
  let(:user) { build_stubbed(:user) }

  before do
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:current_user_mode).and_return(Gitlab::Auth::CurrentUserMode.new(user))
  end

  describe "sidebar" do
    context "when @snippet is not set" do
      it 'renders no sidebar' do
        render

        expect(rendered).not_to have_css("aside.nav-sidebar")
      end
    end
  end
end
