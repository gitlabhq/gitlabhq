# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Admin::Menus::LabelsMenu, feature_category: :navigation do
  it_behaves_like 'Admin menu',
    link: '/admin/labels',
    title: s_('Admin|Labels'),
    icon: 'labels'

  it_behaves_like 'Admin menu without sub menus', active_routes: { controller: :labels }
end
