# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Import::MergeRequestHelpers, type: :helper do
  set(:project) { create(:project, :repository) }
  set(:user) { create(:user) }

  describe '.create_merge_request_without_hooks' do
    let(:iid) { 42 }

    let(:attributes) do
      {
        iid: iid,
        title: 'My Pull Request',
        description: 'This is my pull request',
        source_project_id: project.id,
        target_project_id: project.id,
        source_branch: 'master-42',
        target_branch: 'master',
        state_id: 3,
        author_id: user.id
      }
    end

    subject { helper.create_merge_request_without_hooks(project, attributes, iid) }

    context 'when merge request does not exist' do
      it 'returns a new object' do
        expect(subject.first).not_to be_nil
        expect(subject.second).to eq(false)
      end

      it 'does load all existing objects' do
        5.times do |iid|
          MergeRequest.create!(
            attributes.merge(iid: iid, source_branch: iid.to_s))
        end

        # does ensure that we only load object twice
        # 1. by #insert_and_return_id
        # 2. by project.merge_requests.find
        expect_any_instance_of(MergeRequest).to receive(:attributes)
          .twice.times.and_call_original

        expect(subject.first).not_to be_nil
        expect(subject.second).to eq(false)
      end
    end

    context 'when merge request does exist' do
      before do
        MergeRequest.create!(attributes)
      end

      it 'returns an existing object' do
        expect(subject.first).not_to be_nil
        expect(subject.second).to eq(true)
      end
    end

    context 'when project is deleted' do
      before do
        project.delete
      end

      it 'returns an existing object' do
        expect(subject.first).to be_nil
      end
    end
  end
end
