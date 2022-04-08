# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::CleanupDraftDataFromFaultyRegex, :migration, schema: 20220326161803 do
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

  context "mr.draft == true, and title matches the leaky regex and not the corrected regex" do
    let(:mr_ids) { merge_requests.all.collect(&:id) }

    before do
      draft_prefixes.each do |prefix|
        (1..4).each do |n|
          create_merge_request(
            title: "#{prefix} This is a title",
            draft: true,
            state_id: 1
          )
        end
      end

      create_merge_request(title: "This has draft in the title", draft: true, state_id: 1)
    end

    it "updates all open draft merge request's draft field to true" do
      expect { subject.perform(mr_ids.first, mr_ids.last) }
        .to change { MergeRequest.where(draft: true).count }
        .by(-1)
    end

    it "marks successful slices as completed" do
      expect(subject).to receive(:mark_job_as_succeeded).with(mr_ids.first, mr_ids.last)

      subject.perform(mr_ids.first, mr_ids.last)
    end
  end
end
