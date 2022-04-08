# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BatchingStrategies::BackfillIssueWorkItemTypeBatchingStrategy, '#next_batch', schema: 20220326161803 do # rubocop:disable Layout/LineLength
  # let! can't be used in migration specs because all tables but `work_item_types` are deleted after each spec
  let!(:issue_type_enum) { { issue: 0, incident: 1, test_case: 2, requirement: 3, task: 4 } }
  let!(:namespace) { table(:namespaces).create!(name: 'namespace', path: 'namespace') }
  let!(:project) { table(:projects).create!(namespace_id: namespace.id) }
  let!(:issues_table) { table(:issues) }
  let!(:task_type) { table(:work_item_types).find_by!(namespace_id: nil, base_type: issue_type_enum[:task]) }

  let!(:issue1) { issues_table.create!(project_id: project.id, issue_type: issue_type_enum[:issue]) }
  let!(:task1) { issues_table.create!(project_id: project.id, issue_type: issue_type_enum[:task]) }
  let!(:issue2) { issues_table.create!(project_id: project.id, issue_type: issue_type_enum[:issue]) }
  let!(:issue3) { issues_table.create!(project_id: project.id, issue_type: issue_type_enum[:issue]) }
  let!(:task2) { issues_table.create!(project_id: project.id, issue_type: issue_type_enum[:task]) }
  let!(:incident1) { issues_table.create!(project_id: project.id, issue_type: issue_type_enum[:incident]) }
  # test_case is EE only, but enum values exist on the FOSS model
  let!(:test_case1) { issues_table.create!(project_id: project.id, issue_type: issue_type_enum[:test_case]) }

  let!(:task3) do
    issues_table.create!(project_id: project.id, issue_type: issue_type_enum[:task], work_item_type_id: task_type.id)
  end

  let!(:task4) { issues_table.create!(project_id: project.id, issue_type: issue_type_enum[:task]) }

  let!(:batching_strategy) { described_class.new(connection: ActiveRecord::Base.connection) }

  context 'when issue_type is issue' do
    let(:job_arguments) { [issue_type_enum[:issue], 'irrelevant_work_item_id'] }

    context 'when starting on the first batch' do
      it 'returns the bounds of the next batch' do
        batch_bounds = next_batch(issue1.id, 2)

        expect(batch_bounds).to match_array([issue1.id, issue2.id])
      end
    end

    context 'when additional batches remain' do
      it 'returns the bounds of the next batch' do
        batch_bounds = next_batch(issue2.id, 2)

        expect(batch_bounds).to match_array([issue2.id, issue3.id])
      end
    end

    context 'when on the final batch' do
      it 'returns the bounds of the next batch' do
        batch_bounds = next_batch(issue3.id, 2)

        expect(batch_bounds).to match_array([issue3.id, issue3.id])
      end
    end

    context 'when no additional batches remain' do
      it 'returns nil' do
        batch_bounds = next_batch(issue3.id + 1, 1)

        expect(batch_bounds).to be_nil
      end
    end
  end

  context 'when issue_type is incident' do
    let(:job_arguments) { [issue_type_enum[:incident], 'irrelevant_work_item_id'] }

    context 'when starting on the first batch' do
      it 'returns the bounds of the next batch with only one element' do
        batch_bounds = next_batch(incident1.id, 2)

        expect(batch_bounds).to match_array([incident1.id, incident1.id])
      end
    end
  end

  context 'when issue_type is requirement and there are no matching records' do
    let(:job_arguments) { [issue_type_enum[:requirement], 'irrelevant_work_item_id'] }

    context 'when starting on the first batch' do
      it 'returns nil' do
        batch_bounds = next_batch(1, 2)

        expect(batch_bounds).to be_nil
      end
    end
  end

  context 'when issue_type is task' do
    let(:job_arguments) { [issue_type_enum[:task], 'irrelevant_work_item_id'] }

    context 'when starting on the first batch' do
      it 'returns the bounds of the next batch' do
        batch_bounds = next_batch(task1.id, 2)

        expect(batch_bounds).to match_array([task1.id, task2.id])
      end
    end

    context 'when additional batches remain' do
      it 'returns the bounds of the next batch, does not skip records where FK is already set' do
        batch_bounds = next_batch(task2.id, 2)

        expect(batch_bounds).to match_array([task2.id, task3.id])
      end
    end

    context 'when on the final batch' do
      it 'returns the bounds of the next batch' do
        batch_bounds = next_batch(task4.id, 2)

        expect(batch_bounds).to match_array([task4.id, task4.id])
      end
    end

    context 'when no additional batches remain' do
      it 'returns nil' do
        batch_bounds = next_batch(task4.id + 1, 1)

        expect(batch_bounds).to be_nil
      end
    end
  end

  def next_batch(min_value, batch_size)
    batching_strategy.next_batch(
      :issues,
      :id,
      batch_min_value: min_value,
      batch_size: batch_size,
      job_arguments: job_arguments
    )
  end
end
