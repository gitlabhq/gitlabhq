# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDraftStatusOnMergeRequests do
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
    before do
      draft_prefixes.each do |prefix|
        (1..4).each do |n|
          create_merge_request(
            title: "#{prefix} This is a title",
            draft: false,
            state_id: n
          )
        end
      end
    end

    it "updates all open draft merge request's draft field to true" do
      mr_count = merge_requests.all.count
      mr_ids = merge_requests.all.collect(&:id)

      expect { subject.perform(mr_ids.first, mr_ids.last) }
        .to change { MergeRequest.where(draft: false).count }
        .from(mr_count).to(mr_count - draft_prefixes.length)
    end
  end
end
