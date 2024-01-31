# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/organization', feature_category: :cell do
  let_it_be(:organization) { build_stubbed(:organization) }
  let_it_be(:current_user) { build_stubbed(:user, :admin) }

  before do
    allow(view).to receive(:current_user).and_return(current_user)
    allow(view).to receive(:current_user_mode).and_return(Gitlab::Auth::CurrentUserMode.new(current_user))
    allow(view).to receive(:users_path).and_return('/root')
  end

  describe 'navigation' do
    it 'calls organization_layout_nav and sets @nav instance variable' do
      expect(view).to receive(:organization_layout_nav).and_return('your_work')

      render

      expect(view.instance_variable_get(:@nav)).to eq('your_work')
    end
  end
end
