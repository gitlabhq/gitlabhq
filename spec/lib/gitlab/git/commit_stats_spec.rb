# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Git::CommitStats do
  # `freeze: false` is required in this spec: one or more `let_it_be` subjects
  # cannot be frozen by default (deep_freeze traversal failure, a non-AR
  # subject, or an in-memory mutation that survives reload/refind). Do not
  # drop these opt-outs or convert them to `let_it_be_with_reload`/`refind`
  # (see gitlab-org/gitlab#602925).
  let_it_be(:project, freeze: false) { create(:project, :repository) }

  let(:repository) { project.repository.raw }
  let(:commit) { Gitlab::Git::Commit.find(repository, TestEnv::BRANCH_SHA['feature']) }

  def verify_stats!
    stats = described_class.new(repository, commit)

    expect(stats).to have_attributes(
      additions: eq(5),
      deletions: eq(0),
      files: eq(1),
      total: eq(5)
    )
  end

  it 'returns commit stats and caches them', :use_clean_rails_redis_caching do
    expect(repository.gitaly_commit_client).to receive(:commit_stats).with(commit.id).and_call_original

    verify_stats!

    expect(Rails.cache.fetch("commit_stats:#{repository.gl_project_path}:#{commit.id}")).to eq([5, 0, 1])

    expect(repository.gitaly_commit_client).not_to receive(:commit_stats)

    verify_stats!
  end

  it 'handles old cache format gracefully', :use_clean_rails_redis_caching do
    old_cache_key = "commit_stats:#{repository.gl_project_path}:#{commit.id}"
    Rails.cache.write(old_cache_key, [5, 0])

    expect(repository.gitaly_commit_client).to receive(:commit_stats).with(commit.id).and_call_original

    stats = described_class.new(repository, commit)

    expect(stats).to have_attributes(
      additions: eq(5),
      deletions: eq(0),
      files: eq(1),
      total: eq(5)
    )
    expect(Rails.cache.fetch(old_cache_key)).to eq([5, 0, 1])
  end
end
