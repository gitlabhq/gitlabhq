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
end
