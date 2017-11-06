require 'spec_helper'

describe Gitlab::Git::HooksService, seed_helper: true do
  let(:gl_id) { 'user-456' }
  let(:gl_username) { 'janedoe' }
  let(:user) { Gitlab::Git::User.new(gl_username, 'Jane Doe', 'janedoe@example.com', gl_id) }
  let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH, 'project-123') }
  let(:service) { described_class.new }
  let(:blankrev) { Gitlab::Git::BLANK_SHA }
  let(:oldrev) { SeedRepo::Commit::PARENT_ID }
  let(:newrev) { SeedRepo::Commit::ID }
  let(:ref) { 'refs/heads/feature' }

  describe '#execute' do
    context 'when receive hooks were successful' do
      let(:hook) { double(:hook) }

      it 'calls all three hooks' do
        expect(Gitlab::Git::Hook).to receive(:new).exactly(3).times.and_return(hook)
        expect(hook).to receive(:trigger).with(gl_id, gl_username, blankrev, newrev, ref)
          .exactly(3).times.and_return([true, nil])

        service.execute(user, repository, blankrev, newrev, ref) { }
      end
    end

    context 'when pre-receive hook failed' do
      it 'does not call post-receive hook' do
        expect(service).to receive(:run_hook).with('pre-receive').and_return([false, ''])
        expect(service).not_to receive(:run_hook).with('post-receive')

        expect do
          service.execute(user, repository, blankrev, newrev, ref)
        end.to raise_error(Gitlab::Git::HooksService::PreReceiveError)
      end
    end

    context 'when update hook failed' do
      it 'does not call post-receive hook' do
        expect(service).to receive(:run_hook).with('pre-receive').and_return([true, nil])
        expect(service).to receive(:run_hook).with('update').and_return([false, ''])
        expect(service).not_to receive(:run_hook).with('post-receive')

        expect do
          service.execute(user, repository, blankrev, newrev, ref)
        end.to raise_error(Gitlab::Git::HooksService::PreReceiveError)
      end
    end
  end
end
