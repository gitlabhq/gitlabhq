# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Branches::DeleteMergedService, feature_category: :source_code_management do
  include ProjectForksHelper

  subject(:service) { described_class.new(project, project.first_owner) }

  let(:project) { create(:project, :repository) }

  describe '#execute' do
    it 'deletes a branch that was merged' do
      service.execute

      expect(project.repository.branch_names).not_to include('improve/awesome')
    end

    it 'keeps branch that is unmerged' do
      service.execute

      expect(project.repository.branch_names).to include('feature')
    end

    it 'keeps "master"' do
      service.execute

      expect(project.repository.branch_names).to include('master')
    end

    it 'keeps protected branches' do
      create(:protected_branch, project: project, name: 'improve/awesome')

      service.execute

      expect(project.repository.branch_names).to include('improve/awesome')
    end

    it 'keeps wildcard protected branches' do
      create(:protected_branch, project: project, name: 'improve/*')

      service.execute

      expect(project.repository.branch_names).to include('improve/awesome')
    end

    it 'ignores protected tags' do
      create(:protected_tag, project: project, name: 'improve/*')

      service.execute

      expect(project.repository.branch_names).not_to include('improve/awesome')
    end

    context 'user without rights' do
      let(:user) { create(:user) }

      it 'cannot execute' do
        expect { described_class.new(project, user).execute }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end

    context 'open merge requests' do
      it 'does not delete branches from open merge requests' do
        forked_project = fork_project(project)
        create(:merge_request, :opened, source_project: project, target_project: project, source_branch: 'branch-merged', target_branch: 'master')
        create(:merge_request, :opened, source_project: forked_project, target_project: project, target_branch: 'improve/awesome', source_branch: 'master')

        service.execute

        expect(project.repository.branch_names).to include('branch-merged')
        expect(project.repository.branch_names).to include('improve/awesome')
      end
    end
  end

  describe '#async_execute' do
    it 'calls DeleteMergedBranchesWorker async' do
      expect(DeleteMergedBranchesWorker).to receive(:perform_async)

      service.async_execute
    end
  end
end
