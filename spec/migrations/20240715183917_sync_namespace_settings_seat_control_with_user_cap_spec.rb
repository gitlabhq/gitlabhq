# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SyncNamespaceSettingsSeatControlWithUserCap, feature_category: :consumables_cost_management do
  let(:namespaces) { table(:namespaces) }
  let(:namespace_settings) { table(:namespace_settings) }

  it 'sets the value of seat_control to 1 where new_user_signups_cap has a value' do
    namespace = namespaces.create!(name: 'MyNamespace', path: 'my-namespace')
    settings = namespace_settings.create!(namespace_id: namespace.id, new_user_signups_cap: 10, seat_control: 0)

    migrate!

    expect(settings.reload.seat_control).to eq(1)
  end

  it 'does not change the value of seat_control where new_user_signups_cap is null' do
    namespace = namespaces.create!(name: 'MyNamespace', path: 'my-namespace')
    settings = namespace_settings.create!(namespace_id: namespace.id, new_user_signups_cap: nil, seat_control: 0)

    migrate!

    expect(settings.reload.seat_control).to eq(0)
  end

  it 'sets the value of seat_control for multiple rows' do
    namespace_a = namespaces.create!(name: 'MyNamespaceA', path: 'my-namespace-a')
    settings_a = namespace_settings.create!(namespace_id: namespace_a.id, new_user_signups_cap: 5, seat_control: 0)
    namespace_b = namespaces.create!(name: 'MyNamespaceB', path: 'my-namespace-b')
    settings_b = namespace_settings.create!(namespace_id: namespace_b.id, new_user_signups_cap: nil, seat_control: 0)
    namespace_c = namespaces.create!(name: 'MyNamespaceC', path: 'my-namespace-c')
    settings_c = namespace_settings.create!(namespace_id: namespace_c.id, new_user_signups_cap: 20, seat_control: 0)

    migrate!

    expect(settings_a.reload.seat_control).to eq(1)
    expect(settings_b.reload.seat_control).to eq(0)
    expect(settings_c.reload.seat_control).to eq(1)
  end
end
