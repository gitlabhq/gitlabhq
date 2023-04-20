# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Admin::Menus::MonitoringMenu, feature_category: :navigation do
  it_behaves_like 'Admin menu',
    link: '/admin/system_info',
    title: s_('Admin|Monitoring'),
    icon: 'monitor'

  it_behaves_like 'Admin menu with sub menus'
end
