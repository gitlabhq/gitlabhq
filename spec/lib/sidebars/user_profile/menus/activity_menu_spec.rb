# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserProfile::Menus::ActivityMenu, feature_category: :navigation do
  it_behaves_like 'User profile menu',
    title: s_('UserProfile|Activity'),
    icon: 'history',
    active_route: 'users#activity' do
      let(:link) { "/users/#{user.username}/activity" }
    end
end
