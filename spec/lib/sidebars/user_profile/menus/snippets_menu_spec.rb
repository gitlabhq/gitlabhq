# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserProfile::Menus::SnippetsMenu, feature_category: :navigation do
  it_behaves_like 'User profile menu',
    title: s_('UserProfile|Snippets'),
    icon: 'snippet',
    active_route: 'users#snippets' do
      let(:link) { "/users/#{user.username}/snippets" }
    end
end
