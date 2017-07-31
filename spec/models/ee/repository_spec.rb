require 'spec_helper'

describe EE::Repository do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }

  describe '#new_commits' do
    let(:new_refs) do
      double(:git_rev_list, new_refs: %w[
        c1acaa58bbcbc3eafe538cb8274ba387047b69f8
        5937ac0a7beb003549fc5fd26fc247adbce4a52e
      ])
    end

    it 'delegates to Gitlab::Git::RevList' do
      expect(Gitlab::Git::RevList).to receive(:new).with(
        path_to_repo: repository.path_to_repo,
        newrev: 'aaaabbbbccccddddeeeeffffgggghhhhiiiijjjj').and_return(new_refs)

      commits = repository.new_commits('aaaabbbbccccddddeeeeffffgggghhhhiiiijjjj')

      expect(commits).to eq([
        repository.commit('c1acaa58bbcbc3eafe538cb8274ba387047b69f8'),
        repository.commit('5937ac0a7beb003549fc5fd26fc247adbce4a52e')
      ])
    end
  end
end
