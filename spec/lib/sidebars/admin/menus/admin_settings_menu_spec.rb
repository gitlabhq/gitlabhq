# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Admin::Menus::AdminSettingsMenu, feature_category: :navigation do
  it_behaves_like 'Admin menu',
    link: '/admin/application_settings/general',
    title: s_('Admin|Settings'),
    icon: 'settings',
    separated: true

  it_behaves_like 'Admin menu with sub menus'

  it_behaves_like 'Admin menu with extra container html options',
    extra_container_html_options: { testid: 'admin-settings-menu-link' }
end
