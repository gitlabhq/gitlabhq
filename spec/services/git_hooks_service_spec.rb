require 'spec_helper'

describe GitHooksService do
  include RepoHelpers

  let(:user)    { create :user }
  let(:project) { create :project }
  let(:service) { GitHooksService.new }

  before do
    @blankrev = Gitlab::Git::BLANK_SHA
    @oldrev = sample_commit.parent_id
    @newrev = sample_commit.id
    @ref = 'refs/heads/feature'
    @repo_path = project.repository.path_to_repo
  end

  describe '#execute' do

    context 'when pre hooks were successful' do
      it 'should call post hooks' do
        expect(service).to receive(:run_hook).with('pre-receive').and_return(true)
        expect(service).to receive(:run_hook).with('post-receive').and_return(true)
        expect(service.execute(user, @repo_path, @blankrev, @newrev, @ref) { }).to eq(true)
      end
    end

    context 'when pre hooks failed' do
      it 'should not call post hooks' do
        expect(service).to receive(:run_hook).with('pre-receive').and_return(false)
        expect(service).not_to receive(:run_hook).with('post-receive')

        service.execute(user, @repo_path, @blankrev, @newrev, @ref)
      end
    end

  end
end
