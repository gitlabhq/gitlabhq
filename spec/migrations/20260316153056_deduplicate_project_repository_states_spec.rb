# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeduplicateProjectRepositoryStates, feature_category: :geo_replication do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:shards) { table(:shards) }
  let(:project_repositories) { table(:project_repositories) }
  let(:project_repository_states) { table(:project_repository_states) }

  let!(:organization) { organizations.create!(name: 'test-org', path: 'test-org') }
  let!(:namespace) do
    namespaces.create!(name: 'test-ns', path: 'test-ns', type: 'Group', organization_id: organization.id)
  end

  let!(:shard) { shards.find_or_create_by!(name: 'default') }

  describe '#up' do
    context 'when there are duplicates for a single project_repository_id' do
      let!(:project) { create_project('project-1') }
      let!(:project_repo) { create_project_repository(project) }

      let!(:state_1) { create_state(project_repo, project) }
      let!(:state_2) { create_state(project_repo, project) }
      let!(:state_3) { create_state(project_repo, project) }

      it 'removes duplicates keeping only the record with the highest id' do
        expect(project_repository_states.count).to eq(3)

        schema_migrate_up!

        remaining = project_repository_states.where(project_repository_id: project_repo.id)
        expect(remaining.count).to eq(1)
        expect(remaining.first.id).to eq(state_3.id)
      end
    end

    context 'when there are multiple independent sets of duplicates' do
      let!(:project_a) { create_project('project-a') }
      let!(:project_b) { create_project('project-b') }
      let!(:repo_a) { create_project_repository(project_a) }
      let!(:repo_b) { create_project_repository(project_b) }

      let!(:state_a1) { create_state(repo_a, project_a) }
      let!(:state_a2) { create_state(repo_a, project_a) }
      let!(:state_b1) { create_state(repo_b, project_b) }
      let!(:state_b2) { create_state(repo_b, project_b) }

      it 'removes duplicates from each group keeping the highest id' do
        schema_migrate_up!

        remaining_a = project_repository_states.where(project_repository_id: repo_a.id)
        remaining_b = project_repository_states.where(project_repository_id: repo_b.id)

        expect(remaining_a.count).to eq(1)
        expect(remaining_a.first.id).to eq(state_a2.id)

        expect(remaining_b.count).to eq(1)
        expect(remaining_b.first.id).to eq(state_b2.id)
      end
    end

    context 'when there are no duplicates' do
      let!(:project_a) { create_project('project-a') }
      let!(:project_b) { create_project('project-b') }
      let!(:project_c) { create_project('project-c') }
      let!(:repo_a) { create_project_repository(project_a) }
      let!(:repo_b) { create_project_repository(project_b) }
      let!(:repo_c) { create_project_repository(project_c) }

      let!(:state_a) { create_state(repo_a, project_a) }
      let!(:state_b) { create_state(repo_b, project_b) }
      let!(:state_c) { create_state(repo_c, project_c) }

      it 'preserves all records' do
        expect { schema_migrate_up! }.not_to change { project_repository_states.count }

        expect(project_repository_states.pluck(:id)).to contain_exactly(state_a.id, state_b.id, state_c.id)
      end
    end

    context 'when there is a mix of duplicates and unique records' do
      let!(:project_a) { create_project('project-a') }
      let!(:project_b) { create_project('project-b') }
      let!(:project_c) { create_project('project-c') }
      let!(:repo_a) { create_project_repository(project_a) }
      let!(:repo_b) { create_project_repository(project_b) }
      let!(:repo_c) { create_project_repository(project_c) }

      let!(:state_a1) { create_state(repo_a, project_a) }
      let!(:state_a2) { create_state(repo_a, project_a) }
      let!(:state_a3) { create_state(repo_a, project_a) }
      let!(:state_b) { create_state(repo_b, project_b) }
      let!(:state_c1) { create_state(repo_c, project_c) }
      let!(:state_c2) { create_state(repo_c, project_c) }

      it 'removes only the duplicates and preserves unique records' do
        schema_migrate_up!

        expect(project_repository_states.count).to eq(3)
        expect(project_repository_states.pluck(:id)).to contain_exactly(state_a3.id, state_b.id, state_c2.id)
      end
    end

    context 'when the table is empty' do
      it 'runs without error' do
        expect { schema_migrate_up! }.not_to change { project_repository_states.count }.from(0)
      end
    end

    context 'when duplicates have different verification data' do
      let!(:project) { create_project('project-1') }
      let!(:project_repo) { create_project_repository(project) }

      let!(:verified_state) do
        create_state(project_repo, project, verification_state: 2, verification_checksum: 'abc')
      end

      let!(:pending_state) do
        create_state(project_repo, project, verification_state: 0, verification_checksum: nil)
      end

      it 'keeps the record with the highest id regardless of verification data' do
        schema_migrate_up!

        remaining = project_repository_states.where(project_repository_id: project_repo.id)
        expect(remaining.count).to eq(1)
        expect(remaining.first.id).to eq(pending_state.id)
        expect(remaining.first.verification_state).to eq(0)
      end
    end

    context 'when duplicates span batch boundaries' do
      let!(:project) { create_project('project-1') }
      let!(:project_repo) { create_project_repository(project) }

      it 'still removes all duplicates' do
        project_repository_states.create!(
          id: 1,
          project_repository_id: project_repo.id,
          project_id: project.id,
          verification_state: 0
        )

        late_state = project_repository_states.create!(
          id: 2001,
          project_repository_id: project_repo.id,
          project_id: project.id,
          verification_state: 0
        )

        schema_migrate_up!

        remaining = project_repository_states.where(project_repository_id: project_repo.id)
        expect(remaining.count).to eq(1)
        expect(remaining.first.id).to eq(late_state.id)
      end
    end
  end

  describe '#down' do
    let!(:project) { create_project('project-1') }
    let!(:project_repo) { create_project_repository(project) }

    let!(:state_1) { create_state(project_repo, project) }
    let!(:state_2) { create_state(project_repo, project) }

    it 'is a no-op and does not restore deleted records' do
      schema_migrate_up!

      expect(project_repository_states.count).to eq(1)

      expect { schema_migrate_down! }.not_to change { project_repository_states.count }.from(1)
    end
  end

  private

  def create_project(name)
    project_namespace = namespaces.create!(name: "ns-#{name}",
      path: "ns-#{name}",
      type: 'Project',
      organization_id: organization.id)

    projects.create!(
      name: name,
      path: name,
      namespace_id: namespace.id,
      project_namespace_id: project_namespace.id,
      organization_id: organization.id
    )
  end

  def create_project_repository(project)
    project_repositories.create!(
      shard_id: shard.id,
      disk_path: "#{project.path}-repo",
      project_id: project.id
    )
  end

  def create_state(project_repo, project, **attrs)
    project_repository_states.create!(
      {
        project_repository_id: project_repo.id,
        project_id: project.id,
        verification_state: 0
      }.merge(attrs)
    )
  end
end
