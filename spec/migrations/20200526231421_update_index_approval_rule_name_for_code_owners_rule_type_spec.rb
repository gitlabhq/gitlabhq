# frozen_string_literal: true

require 'spec_helper'
require_migration!('update_index_approval_rule_name_for_code_owners_rule_type')

RSpec.describe UpdateIndexApprovalRuleNameForCodeOwnersRuleType do
  let(:migration) { described_class.new }

  let(:approval_rules) { table(:approval_merge_request_rules) }
  let(:namespace) { table(:namespaces).create!(name: 'gitlab', path: 'gitlab') }

  let(:project) do
    table(:projects).create!(
      namespace_id: namespace.id,
      name: 'gitlab',
      path: 'gitlab'
    )
  end

  let(:merge_request) do
    table(:merge_requests).create!(
      target_project_id: project.id,
      source_project_id: project.id,
      target_branch: 'feature',
      source_branch: 'master'
    )
  end

  let(:index_names) do
    ActiveRecord::Base.connection
      .indexes(:approval_merge_request_rules)
      .collect(&:name)
  end

  def create_sectional_approval_rules
    approval_rules.create!(
      merge_request_id: merge_request.id,
      name: "*.rb",
      code_owner: true,
      rule_type: 2,
      section: "First Section"
    )

    approval_rules.create!(
      merge_request_id: merge_request.id,
      name: "*.rb",
      code_owner: true,
      rule_type: 2,
      section: "Second Section"
    )
  end

  def create_two_matching_nil_section_approval_rules
    2.times do
      approval_rules.create!(
        merge_request_id: merge_request.id,
        name: "nil_section",
        code_owner: true,
        rule_type: 2
      )
    end
  end

  before do
    approval_rules.delete_all
  end

  describe "#up" do
    it "creates the new index and removes the 'legacy' indices" do
      # Confirm that existing legacy indices prevent duplicate entries
      #
      expect { create_sectional_approval_rules }
        .to raise_exception(ActiveRecord::RecordNotUnique)
      expect { create_two_matching_nil_section_approval_rules }
        .to raise_exception(ActiveRecord::RecordNotUnique)

      approval_rules.delete_all

      disable_migrations_output { migrate! }

      # After running the migration, expect `section == nil` rules to still be
      #   blocked by the legacy indices, but sectional rules are allowed.
      #
      expect { create_sectional_approval_rules }
        .to change { approval_rules.count }.by(2)
      expect { create_two_matching_nil_section_approval_rules }
        .to raise_exception(ActiveRecord::RecordNotUnique)

      # Attempt to rerun the creation of sectional rules, and see that sectional
      #   rules are unique by section
      #
      expect { create_sectional_approval_rules }
        .to raise_exception(ActiveRecord::RecordNotUnique)

      expect(index_names).to include(
        described_class::SECTIONAL_INDEX_NAME,
        described_class::LEGACY_INDEX_NAME_RULE_TYPE,
        described_class::LEGACY_INDEX_NAME_CODE_OWNERS
      )
    end
  end

  describe "#down" do
    context "run as FOSS" do
      before do
        expect(Gitlab).to receive(:ee?).twice.and_return(false)
      end

      it "recreates legacy indices, but does not invoke EE-specific code" do
        disable_migrations_output { migrate! }

        expect(index_names).to include(
          described_class::SECTIONAL_INDEX_NAME,
          described_class::LEGACY_INDEX_NAME_RULE_TYPE,
          described_class::LEGACY_INDEX_NAME_CODE_OWNERS
        )

        # Since ApprovalMergeRequestRules are EE-specific, we expect none to be
        #   deleted during the migration.
        #
        expect { disable_migrations_output { migration.down } }
          .not_to change { approval_rules.count }

        index_names = ActiveRecord::Base.connection
          .indexes(:approval_merge_request_rules)
          .collect(&:name)

        expect(index_names).not_to include(described_class::SECTIONAL_INDEX_NAME)
        expect(index_names).to include(
          described_class::LEGACY_INDEX_NAME_RULE_TYPE,
          described_class::LEGACY_INDEX_NAME_CODE_OWNERS
        )
      end
    end

    context "EE" do
      it "recreates 'legacy' indices and removes duplicate code owner approval rules" do
        skip("This test is skipped under FOSS") unless Gitlab.ee?

        disable_migrations_output { migrate! }

        expect { create_sectional_approval_rules }
          .to change { approval_rules.count }.by(2)
        expect { create_two_matching_nil_section_approval_rules }
          .to raise_exception(ActiveRecord::RecordNotUnique)

        expect(MergeRequests::SyncCodeOwnerApprovalRules)
          .to receive(:new).with(MergeRequest.find(merge_request.id)).once.and_call_original

        # Run the down migration. This will remove the 3 approval rules we create
        #   above, and call MergeRequests::SyncCodeOwnerApprovalRules to recreate
        #   new ones. However, as there is no CODEOWNERS file in this test
        #   context, no approval rules will be created, so we can expect
        #   approval_rules.count to be changed by -3.
        #
        expect { disable_migrations_output { migration.down } }
          .to change { approval_rules.count }.by(-3)

        # Test that the index does not allow us to create the same rules as the
        #   previous sectional index.
        #
        expect { create_sectional_approval_rules }
          .to raise_exception(ActiveRecord::RecordNotUnique)
        expect { create_two_matching_nil_section_approval_rules }
          .to raise_exception(ActiveRecord::RecordNotUnique)

        expect(index_names).not_to include(described_class::SECTIONAL_INDEX_NAME)
        expect(index_names).to include(
          described_class::LEGACY_INDEX_NAME_RULE_TYPE,
          described_class::LEGACY_INDEX_NAME_CODE_OWNERS
        )
      end
    end
  end
end
