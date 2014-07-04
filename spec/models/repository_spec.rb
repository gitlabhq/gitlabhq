require 'spec_helper'

describe Repository do
  include RepoHelpers

  let(:repository) { create(:project).repository }

  describe :branch_names_contains do
    subject { repository.branch_names_contains(sample_commit.id) }

    it { should include('master') }
    it { should_not include('feature') }
    it { should_not include('fix') }
  end

  describe :last_commit_for_path do
    subject { repository.last_commit_for_path(sample_commit.id, '.gitignore').id }

    it { should eq('c1acaa58bbcbc3eafe538cb8274ba387047b69f8') }
  end

  describe :free_branch_name do
    it 'returns the smallest new free branch name' do
      prefix = valid_new_branch_name
      expect(repository.free_branch_name(prefix)).to eq(prefix + '1')
      repository.add_branch(prefix + '1', 'HEAD')
      expect(repository.free_branch_name(prefix)).to eq(prefix + '2')
      repository.rm_branch(prefix + '1')
      expect(repository.free_branch_name(prefix)).to eq(prefix + '1')
    end
  end
end
