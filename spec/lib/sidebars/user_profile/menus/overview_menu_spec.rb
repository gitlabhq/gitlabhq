# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserProfile::Menus::OverviewMenu, feature_category: :navigation do
  it_behaves_like 'User profile menu',
    title: s_('UserProfile|Overview'),
    icon: 'overview',
    active_route: 'users#show' do
      let(:link) { "/#{user.username}" }
    end
end
