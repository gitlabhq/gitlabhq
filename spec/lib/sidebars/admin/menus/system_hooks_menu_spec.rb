# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Admin::Menus::SystemHooksMenu, feature_category: :navigation do
  it_behaves_like 'Admin menu',
    link: '/admin/hooks',
    title: s_('Admin|System hooks'),
    icon: 'hook'

  it_behaves_like 'Admin menu without sub menus', active_routes: { controller: :hooks }
end
