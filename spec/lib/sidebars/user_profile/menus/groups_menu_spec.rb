# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserProfile::Menus::GroupsMenu, feature_category: :navigation do
  it_behaves_like 'User profile menu',
    title: s_('UserProfile|Groups'),
    icon: 'group',
    active_route: 'users#groups' do
      let(:link) { "/users/#{user.username}/groups" }
    end
end
