# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/terms', feature_category: :user_profile do
  let_it_be(:user) { create(:user) }

  before do
    allow(view).to receive(:current_user_mode).and_return(Gitlab::Auth::CurrentUserMode.new(user))
  end

  it_behaves_like 'a layout which reflects the application theme setting'
  it_behaves_like 'a layout which reflects the preferred language'
end
