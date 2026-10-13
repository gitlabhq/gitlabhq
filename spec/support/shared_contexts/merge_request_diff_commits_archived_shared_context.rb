# frozen_string_literal: true

# On GitLab.com the pre-partitioning merge_request_diff_commits table survives as
# merge_request_diff_commits_archived. Elsewhere it does not exist, so build a
# copy of the current table and move one diff's rows into it.
RSpec.shared_context 'with archived merge_request_diff_commits' do
  let(:connection) { MergeRequestDiffCommit.connection }

  before do
    connection.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS merge_request_diff_commits_archived
        (LIKE merge_request_diff_commits INCLUDING DEFAULTS)
    SQL
  end

  after do
    connection.execute('DROP TABLE IF EXISTS merge_request_diff_commits_archived')
  end

  def archive_diff_commits(merge_request_diff)
    connection.execute(<<~SQL)
      INSERT INTO merge_request_diff_commits_archived
      SELECT * FROM merge_request_diff_commits
      WHERE merge_request_diff_id = #{merge_request_diff.id.to_i}
    SQL

    MergeRequestDiffCommit.where(merge_request_diff_id: merge_request_diff.id).delete_all
    merge_request_diff.reset
  end
end
