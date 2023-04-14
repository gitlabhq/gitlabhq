# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Admin::Menus::CiCdMenu, feature_category: :navigation do
  it_behaves_like 'Admin menu',
    link: '/admin/runners',
    title: s_('Admin|CI/CD'),
    icon: 'rocket'

  it_behaves_like 'Admin menu with sub menus'
end
