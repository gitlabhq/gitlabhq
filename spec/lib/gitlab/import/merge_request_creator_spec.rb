# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Import::MergeRequestCreator do
  let(:project) { create(:project, :repository) }

  subject { described_class.new(project) }

  describe '#execute' do
    context 'merge request already exists' do
      let(:merge_request) { create(:merge_request, target_project: project, source_project: project) }
      let(:commits) { merge_request.merge_request_diffs.first.commits }
      let(:attributes) { HashWithIndifferentAccess.new(merge_request.attributes.except("merge_params")) }

      it 'updates the data' do
        commits_count = commits.count
        merge_request.merge_request_diffs.destroy_all # rubocop: disable DestroyAll

        expect(merge_request.merge_request_diffs.count).to eq(0)

        subject.execute(attributes)

        expect(merge_request.reload.merge_request_diffs.count).to eq(1)
        expect(merge_request.reload.merge_request_diffs.first.commits.count).to eq(commits_count)
      end
    end

    context 'new merge request' do
      let(:merge_request) { build(:merge_request, target_project: project, source_project: project) }
      let(:attributes) { HashWithIndifferentAccess.new(merge_request.attributes.except("merge_params")) }

      it 'creates a new merge request' do
        attributes.delete(:id)

        expect { subject.execute(attributes) }.to change { MergeRequest.count }.by(1)

        new_mr = MergeRequest.last
        expect(new_mr.merge_request_diffs.count).to eq(1)
      end
    end
  end
end
