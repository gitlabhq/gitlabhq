# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Admin::Menus::ObservabilityMenu, feature_category: :navigation do
  it_behaves_like 'Admin menu',
    link: '/admin/o11y_service_settings',
    title: s_('Admin|Observability'),
    icon: 'eye'

  it_behaves_like 'Admin menu without sub menus', active_routes: { controller: :o11y_service_settings }
end
