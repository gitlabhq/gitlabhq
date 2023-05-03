# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserProfile::Menus::FollowingMenu, feature_category: :navigation do
  it_behaves_like 'User profile menu',
    title: s_('UserProfile|Following'),
    icon: 'users',
    active_route: 'users#following' do
      let(:link) { "/users/#{user.username}/following" }
    end

  it_behaves_like 'Followers/followees counts', :followees
end
