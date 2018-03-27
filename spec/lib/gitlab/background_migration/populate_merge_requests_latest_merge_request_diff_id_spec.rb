require 'spec_helper'

describe Gitlab::BackgroundMigration::PopulateMergeRequestsLatestMergeRequestDiffId, :migration, schema: 20171026082505 do
  let(:projects_table) { table(:projects) }
  let(:merge_requests_table) { table(:merge_requests) }
  let(:merge_request_diffs_table) { table(:merge_request_diffs) }

  let(:project) { projects_table.create!(name: 'gitlab', path: 'gitlab-org/gitlab-ce') }

  def create_mr!(name, diffs: 0)
    merge_request =
      merge_requests_table.create!(target_project_id: project.id,
                                   target_branch: 'master',
                                   source_project_id: project.id,
                                   source_branch: name,
                                   title: name)

    diffs.times do
      merge_request_diffs_table.create!(merge_request_id: merge_request.id)
    end

    merge_request
  end

  def diffs_for(merge_request)
    merge_request_diffs_table.where(merge_request_id: merge_request.id)
  end

  describe '#perform' do
    it 'ignores MRs without diffs' do
      merge_request_without_diff = create_mr!('without_diff')
      mr_id = merge_request_without_diff.id

      expect(merge_request_without_diff.latest_merge_request_diff_id).to be_nil

      expect { subject.perform(mr_id, mr_id) }
        .not_to change { merge_request_without_diff.reload.latest_merge_request_diff_id }
    end

    it 'ignores MRs that have a diff ID already set' do
      merge_request_with_multiple_diffs = create_mr!('with_multiple_diffs', diffs: 3)
      diff_id = diffs_for(merge_request_with_multiple_diffs).minimum(:id)
      mr_id = merge_request_with_multiple_diffs.id

      merge_request_with_multiple_diffs.update!(latest_merge_request_diff_id: diff_id)

      expect { subject.perform(mr_id, mr_id) }
        .not_to change { merge_request_with_multiple_diffs.reload.latest_merge_request_diff_id }
    end

    it 'migrates multiple MR diffs to the correct values' do
      merge_requests = Array.new(3).map.with_index { |_, i| create_mr!(i, diffs: 3) }

      subject.perform(merge_requests.first.id, merge_requests.last.id)

      merge_requests.each do |merge_request|
        expect(merge_request.reload.latest_merge_request_diff_id)
          .to eq(diffs_for(merge_request).maximum(:id))
      end
    end
  end
end
