# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDraftStatusOnMergeRequestsWithCorrectedRegex,
  :migration, schema: 20220326161803 do
  let(:namespaces)     { table(:namespaces) }
  let(:projects)       { table(:projects) }
  let(:merge_requests) { table(:merge_requests) }

  let(:group)   { namespaces.create!(name: 'gitlab', path: 'gitlab') }
  let(:project) { projects.create!(namespace_id: group.id) }

  let(:draft_prefixes) { ["[Draft]", "(Draft)", "Draft:", "Draft", "[WIP]", "WIP:", "WIP"] }

  def create_merge_request(params)
    common_params = {
      target_project_id: project.id,
      target_branch: 'feature1',
      source_branch: 'master'
    }

    merge_requests.create!(common_params.merge(params))
  end

  context "for MRs with #draft? == true titles but draft attribute false" do
    let(:mr_ids) { merge_requests.all.collect(&:id) }

    before do
      draft_prefixes.each do |prefix|
        (1..4).each do |n|
          create_merge_request(
            title: "#{prefix} This is a title",
            draft: false,
            state_id: n
          )

          create_merge_request(
            title: "This is a title with the #{prefix} in a weird spot",
            draft: false,
            state_id: n
          )
        end
      end
    end

    it "updates all eligible draft merge request's draft field to true" do
      mr_count = merge_requests.all.count

      expect { subject.perform(mr_ids.first, mr_ids.last) }
        .to change { MergeRequest.where(draft: false).count }
        .from(mr_count).to(mr_count - draft_prefixes.length)
    end

    it "marks successful slices as completed" do
      expect(subject).to receive(:mark_job_as_succeeded).with(mr_ids.first, mr_ids.last)

      subject.perform(mr_ids.first, mr_ids.last)
    end

    it_behaves_like 'marks background migration job records' do
      let!(:non_eligible_mrs) do
        Array.new(2) do
          create_merge_request(
            title: "Not a d-r-a-f-t 1",
            draft: false,
            state_id: 1
          )
        end
      end

      let(:arguments) { [non_eligible_mrs.first.id, non_eligible_mrs.last.id] }
    end
  end
end
