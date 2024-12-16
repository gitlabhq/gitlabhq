# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Branches::DeleteService, feature_category: :source_code_management do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:user) { create(:user) }

  subject(:service) { described_class.new(project, user) }

  shared_examples 'a deleted branch' do |branch_name|
    before do
      allow(Ci::RefDeleteUnlockArtifactsWorker).to receive(:perform_async)
    end

    it 'removes the branch' do
      expect(branch_exists?(branch_name)).to be true

      result = service.execute(branch_name)

      expect(result.status).to eq :success
      expect(branch_exists?(branch_name)).to be false
    end

    it 'calls the RefDeleteUnlockArtifactsWorker' do
      expect(Ci::RefDeleteUnlockArtifactsWorker).to receive(:perform_async).with(project.id, user.id, "refs/heads/#{branch_name}")

      service.execute(branch_name)
    end
  end

  describe '#execute' do
    context 'when user has access to push to repository' do
      before do
        project.add_developer(user)
      end

      it_behaves_like 'a deleted branch', 'feature'

      context 'when Gitlab::Git::CommandError is raised' do
        before do
          allow(repository).to receive(:rm_branch) do
            raise Gitlab::Git::CommandError, 'Could not update patch'
          end
        end

        it 'handles and returns error' do
          result = service.execute('feature')

          expect(result.status).to eq(:error)
          expect(result.message).to eq('Could not update patch')
          expect(result.payload[:branch]).to be_kind_of(Gitlab::Git::Branch)
        end
      end

      context 'when branch name is empty' do
        it 'handles and returns error' do
          result = service.execute('')

          expect(result.status).to eq(:error)
          expect(result.message).to eq('No such branch')
          expect(result.payload[:branch]).to be_nil
        end
      end

      context 'when Gitaly fails to remove branch' do
        before do
          allow(repository).to receive(:rm_branch).and_return(false)
        end

        it 'handles and returns error' do
          result = service.execute('feature')

          expect(result.status).to eq(:error)
          expect(result.message).to eq('Failed to remove branch')
          expect(result.payload[:branch]).to be_kind_of(Gitlab::Git::Branch)
        end
      end
    end

    context 'when user does not have access to push to repository' do
      it 'does not remove branch' do
        expect(branch_exists?('feature')).to be true

        result = service.execute('feature')

        expect(result.status).to eq :error
        expect(result.message).to eq 'You dont have push access to repo'
        expect(result.payload[:branch]).to be_nil
        expect(branch_exists?('feature')).to be true
      end
    end
  end

  def branch_exists?(branch_name)
    repository.ref_exists?("refs/heads/#{branch_name}")
  end
end
