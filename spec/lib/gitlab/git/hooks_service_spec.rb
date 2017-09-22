require 'spec_helper'

describe Gitlab::Git::HooksService, seed_helper: true do
  let(:user) { Gitlab::Git::User.new('Jane Doe', 'janedoe@example.com', 'user-456') }
  let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH, 'project-123') }
  let(:service) { described_class.new }

  before do
    @blankrev = Gitlab::Git::BLANK_SHA
    @oldrev = SeedRepo::Commit::PARENT_ID
    @newrev = SeedRepo::Commit::ID
    @ref = 'refs/heads/feature'
  end

  describe '#execute' do
    context 'when receive hooks were successful' do
      it 'calls post-receive hook' do
        hook = double(trigger: [true, nil])
        expect(Gitlab::Git::Hook).to receive(:new).exactly(3).times.and_return(hook)

        service.execute(user, repository, @blankrev, @newrev, @ref) { }
      end
    end

    context 'when pre-receive hook failed' do
      it 'does not call post-receive hook' do
        expect(service).to receive(:run_hook).with('pre-receive').and_return([false, ''])
        expect(service).not_to receive(:run_hook).with('post-receive')

        expect do
          service.execute(user, repository, @blankrev, @newrev, @ref)
        end.to raise_error(Gitlab::Git::HooksService::PreReceiveError)
      end
    end

    context 'when update hook failed' do
      it 'does not call post-receive hook' do
        expect(service).to receive(:run_hook).with('pre-receive').and_return([true, nil])
        expect(service).to receive(:run_hook).with('update').and_return([false, ''])
        expect(service).not_to receive(:run_hook).with('post-receive')

        expect do
          service.execute(user, repository, @blankrev, @newrev, @ref)
        end.to raise_error(Gitlab::Git::HooksService::PreReceiveError)
      end
    end
  end
end
