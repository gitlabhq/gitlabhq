# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupOrphanedPackagesNugetSymbols, feature_category: :geo_replication do
  let(:migration) { described_class.new }

  let(:organizations) { table(:organizations) }
  let(:namespaces)    { table(:namespaces) }
  let(:projects)      { table(:projects) }
  let(:symbols)       { table(:packages_nuget_symbols) }

  let!(:organization) { organizations.create!(path: 'test-org') }
  let!(:namespace) do
    namespaces.create!(name: 'test-group', path: 'test-group', type: 'Group', organization_id: organization.id)
  end

  let!(:project) do
    projects.create!(name: 'test-project', namespace_id: namespace.id, project_namespace_id: namespace.id,
      organization_id: organization.id)
  end

  def create_symbol(key_suffix, project_id: project.id)
    symbols.create!(
      created_at: Time.now,
      updated_at: Time.now,
      project_id: project_id,
      size: 100,
      file: "lib/#{key_suffix}.pdb",
      file_path: "lib/#{key_suffix}.pdb",
      signature: "sig#{key_suffix}",
      object_storage_key: "key-#{key_suffix}"
    )
  end

  describe '#up' do
    it 'deletes symbols whose project_id references a non-existent project' do
      valid_sym = create_symbol('a')

      orphaned_sym = create_symbol('b')
      orphaned_sym.update_column(:project_id, non_existing_record_id)

      expect { migration.up }
        .to change { symbols.count }.from(2).to(1)

      expect(symbols.exists?(valid_sym.id)).to be(true)
      expect(symbols.exists?(orphaned_sym.id)).to be(false)
    end

    it 'does not delete symbols with valid projects' do
      create_symbol('a')
      create_symbol('b')

      expect { migration.up }.not_to change { symbols.count }
    end
  end

  describe '#down' do
    it 'is a no-op' do
      expect { migration.down }.not_to change { symbols.count }
    end
  end
end
