# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserProfile::Menus::StarredProjectsMenu, feature_category: :navigation do
  it_behaves_like 'User profile menu',
    title: s_('UserProfile|Starred projects'),
    icon: 'star-o',
    active_route: 'users#starred' do
      let(:link) { "/users/#{user.username}/starred" }
    end
end
