# frozen_string_literal: true

module MergeRequestDiffCommitsHelpers
  # `MergeRequestDiffCommit.read_new_commits_table?` is the single decision point for commit
  # query shape, so specs stub it rather than the feature flag and the partition check it
  # composes. Those two are covered on their own in the model spec.
  #
  # It cannot be derived from the test schema: `merge_request_diff_commits` is not
  # partitioned there until the swap migration.
  def stub_read_new_commits_table(enabled = true)
    allow(MergeRequestDiffCommit).to receive(:read_new_commits_table?).and_return(enabled)
  end
end

RSpec.configure do |config|
  config.include MergeRequestDiffCommitsHelpers
end
