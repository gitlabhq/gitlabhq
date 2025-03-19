# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveLeftoverRoutes, :migration, feature_category: :groups_and_projects do
  let(:deleted_records) { table(:loose_foreign_keys_deleted_records) }
  let(:routes) { table(:routes) }
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }

  let(:organization_1) { table(:organizations).create!(name: 'Organization 1', path: 'organization-1') }

  let!(:namespace_1) do
    namespaces.create!(name: 'Namespace 1', path: 'namespace-1', organization_id: organization_1.id)
  end

  let!(:namespace_2) do
    namespaces.create!(name: 'Namespace 2', path: 'namespace-2', organization_id: organization_1.id)
  end

  let!(:namespace_3) do
    namespaces.create!(name: 'Namespace 3', path: 'namespace-3', organization_id: organization_1.id)
  end

  let!(:routes_1) do
    routes.create!(source_id: namespace_1.id, namespace_id: namespace_1.id, source_type: 'Namespace',
      name: namespace_1.name, path: namespace_1.path)
  end

  let!(:routes_2) do
    routes.create!(source_id: namespace_2.id, namespace_id: namespace_2.id, source_type: 'Namespace',
      name: namespace_2.name, path: namespace_2.path)
  end

  let!(:routes_3) do
    routes.create!(source_id: namespace_3.id, namespace_id: namespace_3.id, source_type: 'Namespace',
      name: namespace_3.name, path: namespace_3.path)
  end

  before do
    deleted_records.create!(fully_qualified_table_name: 'public.namespaces', primary_key_value: namespace_1.id,
      status: 1)
    # Ignore status 2
    deleted_records.create!(fully_qualified_table_name: 'public.namespaces', primary_key_value: namespace_3.id,
      status: 2)
  end

  it 'removes routes for deleted namespaces' do
    migrate!

    expect(routes.where(id: routes_1.id).exists?).to be(false)
    expect(routes.where(id: routes_2.id).exists?).to be(true)
    expect(routes.where(id: routes_3.id).exists?).to be(true)
  end

  it 'does not remove routes for non-deleted namespaces' do
    migrate!

    expect(routes.find_by(source_id: namespace_2.id)).to be_present
  end

  it 'handles empty deleted records' do
    deleted_records.delete_all

    expect { migrate! }.not_to raise_error
    expect(routes.count).to eq(3)
  end

  it 'handles empty routes table' do
    routes.delete_all

    expect { migrate! }.not_to raise_error
    expect(routes.count).to eq(0)
  end
end
