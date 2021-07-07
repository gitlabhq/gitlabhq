# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Commits::CommitPatchService do
  describe '#execute' do
    let(:patches) do
      patches_folder = Rails.root.join('spec/fixtures/patchfiles')
      content_1 = File.read(File.join(patches_folder, "0001-This-does-not-apply-to-the-feature-branch.patch"))
      content_2 = File.read(File.join(patches_folder, "0001-A-commit-from-a-patch.patch"))

      [content_1, content_2]
    end

    let(:user) { project.creator }
    let(:branch_name) { 'branch-with-patches' }
    let(:project) { create(:project, :repository) }
    let(:start_branch) { nil }
    let(:params) { { branch_name: branch_name, patches: patches, start_branch: start_branch } }

    subject(:service) do
      described_class.new(project, user, params)
    end

    it 'returns a successful result' do
      result = service.execute

      branch = project.repository.find_branch(branch_name)

      expect(result[:status]).to eq(:success)
      expect(result[:result]).to eq(branch.target)
    end

    it 'is based off HEAD when no start ref is passed' do
      service.execute

      merge_base = project.repository.merge_base(project.repository.root_ref, branch_name)

      expect(merge_base).to eq(project.repository.commit('HEAD').sha)
    end

    context 'when specifying a different start branch' do
      let(:start_branch) { 'with-codeowners' }

      it 'is based of the correct branch' do
        service.execute

        merge_base = project.repository.merge_base(start_branch, branch_name)

        expect(merge_base).to eq(project.repository.commit(start_branch).sha)
      end
    end

    shared_examples 'an error response' do |expected_message|
      it 'returns the correct error' do
        result = service.execute

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to match(expected_message)
      end
    end

    context 'when the user does not have access' do
      let(:user) { create(:user) }

      it_behaves_like 'an error response',
                      'You are not allowed to push into this branch'
    end

    context 'when the patches are not valid' do
      let(:patches) { "a" * 2.1.megabytes }

      it_behaves_like 'an error response', 'Patches are too big'
    end

    context 'when the new branch name is invalid' do
      let(:branch_name) { 'HEAD' }

      it_behaves_like 'an error response', 'Branch name is invalid'
    end

    context 'when the patches do not apply' do
      let(:branch_name) { 'feature' }

      it_behaves_like 'an error response', 'Patch failed at'
    end

    context 'when specifying a non existent start branch' do
      let(:start_branch) { 'does-not-exist' }

      it_behaves_like 'an error response', 'Failed to create branch'
    end
  end
end
