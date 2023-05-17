# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Admin::Menus::ApplicationsMenu, feature_category: :navigation do
  it_behaves_like 'Admin menu',
    link: '/admin/applications',
    title: s_('Admin|Applications'),
    icon: 'applications'

  it_behaves_like 'Admin menu without sub menus', active_routes: { controller: :applications }
end
