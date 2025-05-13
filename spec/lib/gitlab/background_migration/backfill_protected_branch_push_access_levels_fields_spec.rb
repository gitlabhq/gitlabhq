# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillProtectedBranchPushAccessLevelsFields, feature_category: :source_code_management do
  let(:connection) { ApplicationRecord.connection }

  let(:migration) do
    described_class.new(
      batch_table: :protected_branch_push_access_levels,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: connection
    )
  end

  shared_context 'for database tables' do
    let(:namespaces) { table(:namespaces) }
    let(:organizations) { table(:organizations) }
    let(:projects) { table(:projects) }
    let(:users) { table(:users) }
    let(:groups) { table(:namespaces) }
    let(:protected_branches) { table(:protected_branches) { |t| t.primary_key = :id } }
    let(:protected_branch_push_access_levels) do
      table(:protected_branch_push_access_levels) do |t|
        t.primary_key = :id
      end
    end
  end

  shared_context 'for organization' do
    let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  end

  shared_context 'for namespaces' do
    let(:namespace1) { namespaces.create!(name: 'namespace 1', path: 'namespace1', organization_id: organization.id) }
    let(:namespace2) { namespaces.create!(name: 'namespace 2', path: 'namespace2', organization_id: organization.id) }
  end

  shared_context 'for projects' do
    let(:project1) do
      projects.create!(
        name: 'project 1',
        path: 'project1',
        namespace_id: namespace1.id,
        project_namespace_id: namespace1.id,
        organization_id: organization.id
      )
    end

    let(:project2) do
      projects.create!(
        name: 'project 2',
        path: 'project2',
        namespace_id: namespace2.id,
        project_namespace_id: namespace2.id,
        organization_id: organization.id
      )
    end
  end

  shared_context 'for users and groups' do
    let(:user) do
      users.create!(
        email: 'test@example.com',
        username: 'test_user',
        projects_limit: 10
      )
    end

    let(:group) do
      groups.create!(
        name: 'test-group',
        path: 'test-group',
        type: 'Group',
        organization_id: organization.id
      )
    end
  end

  shared_context 'for protected branches' do
    let!(:protected_branch1) do
      protected_branches.create!(
        name: 'master',
        namespace_id: namespace1.id
      )
    end

    let!(:protected_branch2) do
      protected_branches.create!(
        name: 'main',
        namespace_id: namespace2.id
      )
    end
  end

  shared_context 'for protected branch push access levels' do
    let!(:protected_branch_push_access_level_1) do
      protected_branch_push_access_levels.create!(
        protected_branch_id: protected_branch1.id,
        access_level: 0,
        user_id: user.id,
        protected_branch_namespace_id: nil,
        protected_branch_project_id: nil
      )
    end
  end

  include_context 'for database tables'
  include_context 'for organization'
  include_context 'for namespaces'
  include_context 'for projects'
  include_context 'for users and groups'
  include_context 'for protected branches'
  include_context 'for protected branch push access levels'

  describe '#perform' do
    context 'when backfilling all fields' do
      it 'backfills the bigint and association fields correctly' do
        migration.perform

        expect(protected_branch_push_access_level_1.reload.protected_branch_project_id)
          .to eq(protected_branch1.project_id)
        expect(protected_branch_push_access_level_1.reload.protected_branch_namespace_id)
          .to eq(protected_branch1.namespace_id)
      end
    end

    context 'when doing filtering' do
      it 'includes the sub-batch filter in the update SQL' do
        expect(connection).to receive(:execute) do |sql|
          expect(sql).to include("WHERE protected_branch_push_access_levels.id = filtered_relation.id")
        end

        migration.perform
      end
    end
  end

  describe "#bigint_column_assignments" do
    subject(:assignment_string) { migration.send(:bigint_column_assignments) }

    context "when some expected bigint columns are present" do
      before do
        allow(migration).to receive(:all_column_names).and_return(
          %w[id_convert_to_bigint protected_branch_id_convert_to_bigint]
        )
      end

      it "returns the expected assignment string" do
        expected = <<~EXPECTED.strip
          ,\n"id_convert_to_bigint" = filtered_relation."id",\n"protected_branch_id_convert_to_bigint" = filtered_relation."protected_branch_id"
        EXPECTED

        expect(assignment_string).to eq(expected)
      end
    end

    context "when none of the expected bigint columns are present" do
      before do
        allow(migration).to receive(:all_column_names).and_return([])
      end

      it "returns an empty string" do
        expect(assignment_string).to eq('')
      end
    end
  end
end
