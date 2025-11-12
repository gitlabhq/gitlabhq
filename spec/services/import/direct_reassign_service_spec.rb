# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::DirectReassignService, feature_category: :importers do
  let_it_be(:import_source_user) do
    create(:import_source_user, :reassignment_in_progress)
  end

  let_it_be(:import_user_source_user) do
    create(:import_source_user, placeholder_user: create(:user, :import_user))
  end

  describe '.model_list' do
    it 'includes expected models and their attributes' do
      model_list = described_class.model_list

      expect(model_list['Issue']).to eq(%w[author_id updated_by_id closed_by_id])
      expect(model_list['MergeRequest']).to eq(%w[author_id updated_by_id merge_user_id])
      expect(model_list['Note']).to eq(%w[author_id])
      expect(model_list['Approval']).to eq(['user_id'])
    end

    it 'only contains attributes with database indexes set', :aggregate_failures do
      def failure_message(model, column)
        <<-MSG
          The column '#{column}' is listed in #{described_class.name}.model_list["#{model}"]
          but '#{model}#{column}' lacks a proper database index.

          Action required:
          - If this is a new column: Add the missing database index
          - If an existing index was removed: Create a replacement index

          Without a proper index, placeholder user reassignment will fail due to poor query performance.
        MSG
      end

      described_class.model_list.each do |model, attributes|
        indexes = ApplicationRecord.connection.indexes(model.constantize.table_name).map { |i| i.columns.first }.uniq

        attributes.each do |attribute|
          next if indexes.include?(attribute)

          expect(described_class.model_list[model].to_a).to exclude(attribute), failure_message(model, attribute)
        end
      end
    end

    it 'contains only base class of models that uses STI' do
      models = described_class.model_list.keys
      base_classes = models.map { |model| model.constantize.base_class.name }.uniq

      expect(models).to match_array(base_classes)
    end
  end

  describe '#execute' do
    let_it_be_with_reload(:other_source_user) do
      create(:import_source_user, :with_reassigned_by_user, :reassignment_in_progress)
    end

    let_it_be(:reassign_to_user_id) { import_source_user.reassign_to_user.id }
    let_it_be(:placeholder_user_id) { import_source_user.placeholder_user.id }
    let_it_be(:other_placeholder_user_id) { other_source_user.placeholder_user.id }

    # MergeRequests
    let_it_be_with_reload(:merge_requests) { create_list(:merge_request, 3, author_id: placeholder_user_id) }

    let_it_be_with_reload(:other_merge_request) do
      create(:merge_request, author_id: other_placeholder_user_id)
    end

    # Approvals
    let_it_be_with_reload(:merge_request_approval) do
      create(:approval, merge_request: other_merge_request, user_id: placeholder_user_id)
    end

    let_it_be_with_reload(:merge_request_approval_placeholder) do
      create(:approval, merge_request: merge_requests[0], user_id: placeholder_user_id)
    end

    let_it_be_with_reload(:merge_request_approval_reassign_to_user) do
      create(:approval, merge_request: merge_requests[0], user_id: reassign_to_user_id)
    end

    let_it_be_with_reload(:other_merge_request_approval) do
      create(:approval, merge_request: merge_requests[0], user_id: other_placeholder_user_id)
    end

    # Issues
    let_it_be_with_reload(:issue) { create(:issue, author_id: placeholder_user_id, closed_by_id: placeholder_user_id) }
    let_it_be_with_reload(:issue_closed) { create(:issue, closed_by_id: placeholder_user_id) }

    # IssueAssignees
    let_it_be_with_reload(:issue_assignee) do
      issue.issue_assignees.create!(user_id: placeholder_user_id)
    end

    let_it_be_with_reload(:issue_assignee_placeholder_user) do
      issue_closed.issue_assignees.create!(user_id: placeholder_user_id)
    end

    let_it_be_with_reload(:issue_assignee_reassign_to_user) do
      issue_closed.issue_assignees.create!(user_id: reassign_to_user_id)
    end

    # Notes
    let_it_be_with_reload(:authored_note) { create(:note, author_id: placeholder_user_id) }

    # Ci::Builds - schema is gitlab_ci
    let_it_be_with_reload(:ci_build) { create(:ci_build, user_id: placeholder_user_id) }

    let(:reassignment_throttling) { Import::ReassignPlaceholderThrottling.new(import_source_user) }

    subject(:direct_reassign) do
      described_class.new(import_source_user, reassignment_throttling: reassignment_throttling, sleep_time: 0)
    end

    context 'when user_mapping_direct_reassignment feature is disabled' do
      before do
        stub_feature_flags(user_mapping_direct_reassignment: false)
      end

      it 'returns early without processing' do
        expect(direct_reassign).not_to receive(:direct_reassign_model_user_references)

        direct_reassign.execute
      end
    end

    context 'when user_mapping_direct_reassignment feature is enabled' do
      it 'reassigns references' do
        expect(direct_reassign).to receive(:direct_reassign_model_user_references).at_least(:once)

        direct_reassign.execute
      end
    end

    it 'updates records ownership' do
      expect { direct_reassign.execute }.to change { merge_requests[0].reload.author_id }
          .from(placeholder_user_id).to(reassign_to_user_id)
          .and change { merge_requests[1].reload.author_id }.from(placeholder_user_id).to(reassign_to_user_id)
          .and change { merge_requests[2].reload.author_id }.from(placeholder_user_id).to(reassign_to_user_id)
          .and change { merge_request_approval.reload.user_id }.from(placeholder_user_id).to(reassign_to_user_id)
          .and change { issue.reload.author_id }.from(placeholder_user_id).to(reassign_to_user_id)
          .and change { issue.reload.closed_by_id }.from(placeholder_user_id).to(reassign_to_user_id)
          .and change { issue_closed.reload.closed_by_id }.from(placeholder_user_id).to(reassign_to_user_id)
          .and change { authored_note.reload.author_id }.from(placeholder_user_id).to(reassign_to_user_id)
          .and change { IssueAssignee.where({ user_id: reassign_to_user_id, issue_id: issue.id }).count }.from(0).to(1)
    end

    it 'does not touch records that would get duplicated' do
      direct_reassign.execute

      expect { direct_reassign.execute }.to not_change { issue_assignee_reassign_to_user.reload.user_id }
        .and not_change { merge_request_approval_reassign_to_user.reload.user_id }
    end

    it 'destroy duplicated records associated with the placeholder user' do
      expect(Import::Framework::Logger).to receive(:warn).with(
        hash_including(
          {
            message: "Destroying contribution due to uniqueness constraint",
            source_user_id: import_source_user.id,
            model: 'Approval'
          }
        )
      )

      expect(Import::Framework::Logger).to receive(:warn).with(
        hash_including(
          {
            message: "Destroying contribution due to uniqueness constraint",
            source_user_id: import_source_user.id,
            model: 'IssueAssignee'
          }
        )
      )

      expect { direct_reassign.execute }.to change { Approval.count }.by(-1)
        .and change { IssueAssignee.count }.by(-1)

      expect(Approval.where(user_id: placeholder_user_id).count).to eq(0)
      expect(IssueAssignee.where(user_id: placeholder_user_id).count).to eq(0)
    end

    it 'raises ExecutionTimeOutError if execution time exceeds the limit' do
      expect_next_instance_of(Gitlab::Utils::ExecutionTracker) do |tracker|
        expect(tracker).to receive(:over_limit?).and_return(false)
        expect(tracker).to receive(:over_limit?).and_return(false)
        expect(tracker).to receive(:over_limit?).and_return(true)
      end

      expect { direct_reassign.execute }.to raise_error(Gitlab::Utils::ExecutionTracker::ExecutionTimeOutError)
    end

    context 'when database is unhealthy' do
      before do
        allow_next_instance_of(Import::ReassignPlaceholderThrottling) do |throttling|
          allow(throttling).to receive(:db_health_check!)
            .and_raise(Import::ReassignPlaceholderThrottling::DatabaseHealthError, 'Database unhealthy')
        end
      end

      it 'returns early without processing and raises DatabaseHealthError' do
        expect(direct_reassign).not_to receive(:direct_reassign_model_user_references)

        expect { direct_reassign.execute }
          .to raise_error Import::ReassignPlaceholderThrottling::DatabaseHealthError, 'Database unhealthy'
      end
    end

    context 'when tables were not available' do
      before do
        allow(described_class).to receive(:model_list)
          .and_return({ "Issue" => ['author_id'], "MergeRequest" => ['author_id'] })

        allow_next_instance_of(Import::ReassignPlaceholderThrottling) do |throttling|
          allow(throttling).to receive(:db_health_check!)
          allow(throttling).to receive(:db_table_unavailable?).with(MergeRequest).and_return(true)
          allow(throttling).to receive(:db_table_unavailable?).with(Issue).and_return(false)
        end
      end

      it 'does not reassign unavailable tables' do
        expect { direct_reassign.execute }.to not_change { merge_requests[0].reload.author_id }
          .and change { issue.reload.author_id }.from(placeholder_user_id).to(reassign_to_user_id)
      end
    end
  end
end
