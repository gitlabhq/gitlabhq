# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Git::CommitStats, :seed_helper do
  let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '', 'group/project') }
  let(:commit) { Gitlab::Git::Commit.find(repository, SeedRepo::Commit::ID) }

  def verify_stats!
    stats = described_class.new(repository, commit)

    expect(stats).to have_attributes(
      additions: eq(11),
      deletions: eq(6),
      total: eq(17)
    )
  end

  it 'returns commit stats and caches them', :use_clean_rails_redis_caching do
    expect(repository.gitaly_commit_client).to receive(:commit_stats).with(commit.id).and_call_original

    verify_stats!

    expect(Rails.cache.fetch("commit_stats:group/project:#{commit.id}")).to eq([11, 6])

    expect(repository.gitaly_commit_client).not_to receive(:commit_stats)

    verify_stats!
  end
end
