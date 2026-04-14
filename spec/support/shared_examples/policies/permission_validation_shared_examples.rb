# frozen_string_literal: true

RSpec.shared_examples 'valid permissions' do
  it 'allows expected permissions', :aggregate_failures do
    expect_allowed(*permissions)
  end

  it 'does not allow unexpected permissions', :aggregate_failures do
    expect_disallowed(*(all_permissions - permissions))
  end
end

RSpec.shared_examples 'prevent all except' do
  let(:denied_permissions) { described_class.ability_map.map.keys - allowed_permissions }

  it 'allows expected permissions', :aggregate_failures do
    expect_allowed(*allowed_permissions)
  end

  it 'does not allow unexpected permissions', :aggregate_failures do
    expect_disallowed(*denied_permissions)
  end
end
