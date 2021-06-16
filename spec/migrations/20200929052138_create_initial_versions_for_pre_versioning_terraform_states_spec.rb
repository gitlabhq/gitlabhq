# frozen_string_literal: true

require 'spec_helper'
require_migration!('create_initial_versions_for_pre_versioning_terraform_states')

RSpec.describe CreateInitialVersionsForPreVersioningTerraformStates do
  let(:namespace) { table(:namespaces).create!(name: 'terraform', path: 'terraform') }
  let(:project) { table(:projects).create!(id: 1, namespace_id: namespace.id) }
  let(:terraform_state_versions) { table(:terraform_state_versions) }

  def create_state!(project, versioning_enabled:)
    table(:terraform_states).create!(
      project_id: project.id,
      uuid: 'uuid',
      file_store: 2,
      file: 'state.tfstate',
      versioning_enabled: versioning_enabled
    )
  end

  describe '#up' do
    context 'for a state that is already versioned' do
      let!(:terraform_state) { create_state!(project, versioning_enabled: true) }

      it 'does not insert a version record' do
        expect { migrate! }.not_to change { terraform_state_versions.count }
      end
    end

    context 'for a state that is not yet versioned' do
      let!(:terraform_state) { create_state!(project, versioning_enabled: false) }

      it 'creates a version using the current state data' do
        expect { migrate! }.to change { terraform_state_versions.count }.by(1)

        migrated_version = terraform_state_versions.last
        expect(migrated_version.terraform_state_id).to eq(terraform_state.id)
        expect(migrated_version.version).to be_zero
        expect(migrated_version.file_store).to eq(terraform_state.file_store)
        expect(migrated_version.file).to eq(terraform_state.file)
        expect(migrated_version.created_at).to be_present
        expect(migrated_version.updated_at).to be_present
      end
    end
  end
end
