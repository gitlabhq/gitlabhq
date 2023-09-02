# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserProfile::Menus::OverviewMenu, feature_category: :navigation do
  it_behaves_like 'User profile menu',
    icon: nil,
    expect_avatar: true,
    avatar_shape: 'circle',
    active_route: 'users#show' do
      let(:link) { "/#{user.username}" }
    end
end
