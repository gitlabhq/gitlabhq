# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddNotNullCheckConstraintMrComplianceViolationsTargetProjectId,
  :migration,
  feature_category: :compliance_management do
  let(:migration) { described_class.new }
  let(:users) { table(:users) }
  let(:projects) { table(:projects) }
  let(:merge_requests) { table(:merge_requests) }
  let(:compliance_violations) { table(:merge_requests_compliance_violations) }
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }

  let(:user) { users.create!(username: 'test_user', email: 'test@example.com', projects_limit: 0) }
  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let(:namespace) do
    namespaces
      .create!(
        name: 'test-group',
        path: 'test-group',
        type: 'Group',
        organization_id: organization.id
      )
      .tap do |group|
        group.update!(traversal_ids: [group.id])
      end
  end

  let(:project) do
    projects.create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      name: 'test project',
      path: 'test-project',
      organization_id: organization.id
    )
  end

  let(:merge_request) do
    merge_requests.create!(
      target_project_id: project.id,
      target_branch: 'master',
      source_branch: 'feature',
      source_project_id: project.id
    )
  end

  describe '#up' do
    context 'when column is NOT NULL' do
      before do
        migration.connection.change_column_null(:merge_requests_compliance_violations, :target_project_id, false)

        compliance_violations.create!(
          violating_user_id: user.id,
          merge_request_id: merge_request.id,
          target_project_id: project.id,
          reason: 0,
          severity_level: 0
        )
      end

      it 'converts NOT NULL constraint to check constraint' do
        migrate!

        column = migration.connection.columns(:merge_requests_compliance_violations).find do |c|
          c.name == 'target_project_id'
        end
        expect(column.null).to be true

        expect do
          compliance_violations.create!(
            violating_user_id: user.id,
            merge_request_id: merge_request.id,
            target_project_id: nil,
            reason: 0,
            severity_level: 0
          )
        end.to raise_error(ActiveRecord::StatementInvalid, /violates check constraint/i)
      end
    end

    context 'when column is already nullable' do
      before do
        compliance_violations.create!(
          violating_user_id: user.id,
          merge_request_id: merge_request.id,
          target_project_id: project.id,
          reason: 0,
          severity_level: 0
        )
      end

      it 'only adds check constraint' do
        migrate!

        expect do
          compliance_violations.create!(
            violating_user_id: user.id,
            merge_request_id: merge_request.id,
            target_project_id: nil,
            reason: 0,
            severity_level: 0
          )
        end.to raise_error(ActiveRecord::StatementInvalid, /violates check constraint/i)
      end
    end
  end

  describe '#down' do
    let!(:violation) do
      compliance_violations.create!(
        violating_user_id: user.id,
        merge_request_id: merge_request.id,
        target_project_id: project.id,
        reason: 0,
        severity_level: 0
      )
    end

    it 'removes the check constraint' do
      migrate!

      expect do
        compliance_violations.create!(
          violating_user_id: user.id,
          merge_request_id: merge_request.id,
          target_project_id: nil,
          reason: 0,
          severity_level: 0
        )
      end.to raise_error(ActiveRecord::StatementInvalid, /violates check constraint/i)

      migration.down

      new_merge_request = merge_requests.create!(
        target_project_id: project.id,
        target_branch: 'master',
        source_branch: 'feature2',
        source_project_id: project.id
      )

      expect do
        compliance_violations.create!(
          violating_user_id: user.id,
          merge_request_id: new_merge_request.id,
          target_project_id: nil,
          reason: 0,
          severity_level: 0
        )
      end.not_to raise_error
    end
  end
end
