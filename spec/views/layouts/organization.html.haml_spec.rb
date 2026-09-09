# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/organization', :with_current_organization, feature_category: :organization do
  let_it_be(:organization) { build_stubbed(:organization) }
  let_it_be(:current_user) { build_stubbed(:user, :admin) }

  before do
    allow(view).to receive_messages(
      current_user: current_user,
      current_user_mode: Gitlab::Auth::CurrentUserMode.new(current_user),
      users_path: '/root'
    )
  end

  describe 'navigation' do
    it 'calls organization_layout_nav and sets @nav instance variable' do
      expect(view).to receive(:organization_layout_nav).and_return('your_work')

      render

      expect(view.instance_variable_get(:@nav)).to eq('your_work')
    end
  end
end
