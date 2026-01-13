# frozen_string_literal: true

RSpec.shared_examples 'valid permissions' do
  it 'allows expected permissions', :aggregate_failures do
    expect_allowed(*permissions)
  end

  it 'does not allow unexpected permissions', :aggregate_failures do
    expect_disallowed(*(all_permissions - permissions))
  end
end
