# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Authz::PermissionGroups::FilteredAssignable, feature_category: :permissions do
  let(:assignable) do
    ::Authz::PermissionGroups::Assignable.new(
      {
        name: 'read_resource',
        description: 'Grants read on resource',
        permissions: %w[read_resource],
        boundaries: %w[group project instance],
        available_for: %w[granular_access_token]
      },
      "#{::Authz::PermissionGroups::Assignable::BASE_PATH}/category/resource/read.yml"
    )
  end

  subject(:filtered) { described_class.new(assignable, boundaries: %w[group project]) }

  it 'overrides boundaries with the filtered set' do
    expect(filtered.boundaries).to eq(%w[group project])
  end

  it 'delegates other methods to the wrapped assignable' do
    expect(filtered.name).to eq('read_resource')
    expect(filtered.description).to eq('Grants read on resource')
    expect(filtered.permissions).to eq([:read_resource])
    expect(filtered.action).to eq('read')
  end

  it 'does not mutate the wrapped assignable' do
    filtered

    expect(assignable.boundaries).to eq(%w[group project instance])
  end
end
