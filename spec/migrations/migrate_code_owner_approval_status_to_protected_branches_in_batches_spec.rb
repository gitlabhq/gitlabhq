# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateCodeOwnerApprovalStatusToProtectedBranchesInBatches do
  let(:namespaces)         { table(:namespaces) }
  let(:projects)           { table(:projects) }
  let(:protected_branches) { table(:protected_branches) }

  let(:namespace) do
    namespaces.create!(
      path: 'gitlab-instance-administrators',
      name: 'GitLab Instance Administrators'
    )
  end

  let(:project) do
    projects.create!(
      namespace_id: namespace.id,
      name: 'GitLab Instance Administration'
    )
  end

  let!(:protected_branch_1) do
    protected_branches.create!(
      name: "branch name",
      project_id: project.id
    )
  end

  describe '#up' do
    context "when there's no projects needing approval" do
      it "doesn't change any protected branch records" do
        expect { migrate! }
          .not_to change { ProtectedBranch.where(code_owner_approval_required: true).count }
      end
    end

    context "when there's a project needing approval" do
      let!(:project_needing_approval) do
        projects.create!(
          namespace_id: namespace.id,
          name: 'GitLab Instance Administration',
          merge_requests_require_code_owner_approval: true
        )
      end

      let!(:protected_branch_2) do
        protected_branches.create!(
          name: "branch name",
          project_id: project_needing_approval.id
        )
      end

      it "changes N protected branch records" do
        expect { migrate! }
          .to change { ProtectedBranch.where(code_owner_approval_required: true).count }
          .by(1)
      end
    end
  end
end
