# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserSettings::Menus::UsageQuotasMenu, feature_category: :navigation do
  it_behaves_like 'User settings menu',
    link: '/-/profile/usage_quotas',
    title: s_('UsageQuota|Usage Quotas'),
    icon: 'quota',
    active_routes: { controller: :usage_quotas }

  it_behaves_like 'User settings menu #render? method'
end
