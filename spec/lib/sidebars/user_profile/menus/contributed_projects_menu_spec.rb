# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserProfile::Menus::ContributedProjectsMenu, feature_category: :navigation do
  it_behaves_like 'User profile menu',
    title: s_('UserProfile|Contributed projects'),
    icon: 'project',
    active_route: 'users#contributed' do
      let(:link) { "/users/#{user.username}/contributed" }
    end
end
