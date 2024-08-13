# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Admin::Menus::DeployKeysMenu, feature_category: :navigation do
  it_behaves_like 'Admin menu',
    link: '/admin/deploy_keys',
    title: s_('Admin|Deploy keys'),
    icon: 'key'

  it_behaves_like 'Admin menu without sub menus', active_routes: { controller: :deploy_keys }
end
