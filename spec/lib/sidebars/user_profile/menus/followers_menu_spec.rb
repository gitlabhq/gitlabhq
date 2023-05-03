# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserProfile::Menus::FollowersMenu, feature_category: :navigation do
  it_behaves_like 'User profile menu',
    title: s_('UserProfile|Followers'),
    icon: 'users',
    active_route: 'users#followers' do
      let(:link) { "/users/#{user.username}/followers" }
    end

  it_behaves_like 'Followers/followees counts', :followers
end
