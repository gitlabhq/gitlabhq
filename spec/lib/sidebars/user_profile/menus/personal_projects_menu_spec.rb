# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserProfile::Menus::PersonalProjectsMenu, feature_category: :navigation do
  it_behaves_like 'User profile menu',
    title: s_('UserProfile|Personal projects'),
    icon: 'project',
    active_route: 'users#projects' do
      let(:link) { "/users/#{user.username}/projects" }
    end
end
