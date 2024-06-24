# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HookData::IssueBuilder, feature_category: :webhooks do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:label) { create(:label, project: project) }
  let_it_be(:issue) { create(:labeled_issue, labels: [label], project: project) }
  let_it_be(:contact) { create(:contact, group: project.group) }
  let_it_be(:issue_contact) { create(:issue_customer_relations_contact, issue: issue, contact: contact) }

  let(:builder) { described_class.new(issue) }
  let(:work_item_type) { 'Issue' }

  subject(:data) { builder.build }

  shared_examples 'valid issue hook data' do
    it 'includes safe attribute' do
      %w[
        assignee_id
        author_id
        closed_at
        confidential
        created_at
        description
        discussion_locked
        due_date
        id
        iid
        last_edited_at
        last_edited_by_id
        milestone_id
        moved_to_id
        duplicated_to_id
        project_id
        relative_position
        state_id
        time_estimate
        title
        updated_at
        updated_by_id
      ].each do |key|
        is_expected.to include(key)
      end
    end

    it 'includes additional attrs' do
      is_expected.to include('type' => work_item_type)
      is_expected.to include(:total_time_spent)
      is_expected.to include(:time_change)
      is_expected.to include(:human_time_estimate)
      is_expected.to include(:human_total_time_spent)
      is_expected.to include(:human_time_change)
      is_expected.to include(:assignee_ids)
      is_expected.to include(:state)
      is_expected.to include(:severity)
    end
  end

  describe '#build' do
    context 'for legacy issues' do
      it_behaves_like 'valid issue hook data'

      it 'includes labels and CR contacts attrs' do
        is_expected.to include('labels' => [label.hook_attrs])
        is_expected.to include('customer_relations_contacts' => [contact.reload.hook_attrs])
      end

      context 'when the issue has an image in the description' do
        let(:issue_with_description) { create(:issue, description: 'test![Issue_Image](/uploads/abc/Issue_Image.png)') }
        let(:builder) { described_class.new(issue_with_description) }

        it 'sets the image to use an absolute URL' do
          expected_path = "#{issue_with_description.project.path_with_namespace}/uploads/abc/Issue_Image.png"

          expect(data[:description])
            .to eq("test![Issue_Image](#{Settings.gitlab.url}/#{expected_path})")
        end
      end
    end

    context 'for work items' do
      let_it_be(:work_item) { create(:work_item) }

      let(:work_item_type) { work_item.work_item_type.name }
      let(:builder) { described_class.new(work_item) }

      # Default work item type issue.
      it_behaves_like 'valid issue hook data'

      context 'when type is task' do
        let_it_be(:work_item) { create(:work_item, :task) }

        it_behaves_like 'valid issue hook data'
      end

      context 'when type is ticket' do
        let_it_be(:work_item) { create(:work_item, :ticket) }

        it_behaves_like 'valid issue hook data'
      end

      context 'when type is incident' do
        # Factory already sets correct work item type
        let_it_be(:work_item) { create(:incident, :with_escalation_status) }

        it_behaves_like 'valid issue hook data'

        it 'includes additional attr' do
          is_expected.to include(:escalation_status)
        end
      end

      context 'when type is requirement' do
        let_it_be(:work_item) { create(:work_item, :requirement) }

        it_behaves_like 'valid issue hook data'
      end

      context 'when type is test case' do
        let_it_be(:work_item) { create(:work_item, :test_case) }

        it_behaves_like 'valid issue hook data'
      end

      context 'when type is objective' do
        let_it_be(:work_item) { create(:work_item, :objective) }

        it_behaves_like 'valid issue hook data'
      end

      context 'when type is key_result' do
        let_it_be(:work_item) { create(:work_item, :key_result) }

        it_behaves_like 'valid issue hook data'
      end

      context 'when type is epic' do
        let_it_be(:work_item) { create(:work_item, :epic) }

        it_behaves_like 'valid issue hook data'
      end
    end
  end
end
