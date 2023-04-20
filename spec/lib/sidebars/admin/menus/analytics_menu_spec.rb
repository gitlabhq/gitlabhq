# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Admin::Menus::AnalyticsMenu, feature_category: :navigation do
  it_behaves_like 'Admin menu',
    link: '/admin/dev_ops_reports',
    title: s_('Admin|Analytics'),
    icon: 'chart'

  it_behaves_like 'Admin menu with sub menus'
end
