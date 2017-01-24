require 'spec_helper'

describe DeleteMergedBranchesService, services: true do
  subject(:service) { described_class.new(project, project.owner) }

  let(:project) { create(:project) }

  context '#execute' do
    context 'unprotected branches' do
      before do
        service.execute
      end

      it 'deletes a branch that was merged' do
        expect(project.repository.branch_names).not_to include('improve/awesome')
      end

      it 'keeps branch that is unmerged' do
        expect(project.repository.branch_names).to include('feature')
      end

      it 'keeps "master"' do
        expect(project.repository.branch_names).to include('master')
      end
    end

    context 'protected branches' do
      before do
        create(:protected_branch, name: 'improve/awesome', project: project)
        service.execute
      end

      it 'keeps protected branch' do
        expect(project.repository.branch_names).to include('improve/awesome')
      end
    end

    context 'user without rights' do
      let(:user) { create(:user) }

      it 'cannot execute' do
        expect { described_class.new(project, user).execute }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end
  end

  context '#async_execute' do
    it 'calls DeleteMergedBranchesWorker async' do
      expect(DeleteMergedBranchesWorker).to receive(:perform_async)

      service.async_execute
    end
  end
end
