require 'rails_helper'

describe MergeRequestDiffCommit do
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }

  describe '#to_hash' do
    subject { merge_request.commits.first }

    it 'returns the same results as Commit#to_hash, except for parent_ids' do
      commit_from_repo = project.repository.commit(subject.sha)
      commit_from_repo_hash = commit_from_repo.to_hash.merge(parent_ids: [])

      expect(subject.to_hash).to eq(commit_from_repo_hash)
    end
  end

  describe '.create_bulk' do
    let(:sha_attribute)  { Gitlab::Database::ShaAttribute.new }
    let(:merge_request_diff_id) { merge_request.merge_request_diff.id }
    let(:commits) do
      [
        project.commit('5937ac0a7beb003549fc5fd26fc247adbce4a52e'),
        project.commit('570e7b2abdd848b95f2f578043fc23bd6f6fd24d')
      ]
    end
    let(:rows) do
      [
        {
          "message": "Add submodule from gitlab.com\n\nSigned-off-by: Dmitriy Zaporozhets \u003cdmitriy.zaporozhets@gmail.com\u003e\n",
          "authored_date": "2014-02-27T10:01:38.000+01:00".to_time,
          "author_name": "Dmitriy Zaporozhets",
          "author_email": "dmitriy.zaporozhets@gmail.com",
          "committed_date": "2014-02-27T10:01:38.000+01:00".to_time,
          "committer_name": "Dmitriy Zaporozhets",
          "committer_email": "dmitriy.zaporozhets@gmail.com",
          "merge_request_diff_id": merge_request_diff_id,
          "relative_order": 0,
          "sha": sha_attribute.serialize("5937ac0a7beb003549fc5fd26fc247adbce4a52e")
        },
        {
          "message": "Change some files\n\nSigned-off-by: Dmitriy Zaporozhets \u003cdmitriy.zaporozhets@gmail.com\u003e\n",
          "authored_date": "2014-02-27T09:57:31.000+01:00".to_time,
          "author_name": "Dmitriy Zaporozhets",
          "author_email": "dmitriy.zaporozhets@gmail.com",
          "committed_date": "2014-02-27T09:57:31.000+01:00".to_time,
          "committer_name": "Dmitriy Zaporozhets",
          "committer_email": "dmitriy.zaporozhets@gmail.com",
          "merge_request_diff_id": merge_request_diff_id,
          "relative_order": 1,
          "sha": sha_attribute.serialize("570e7b2abdd848b95f2f578043fc23bd6f6fd24d")
        }
      ]
    end

    subject { described_class.create_bulk(merge_request_diff_id, commits) }

    it 'inserts the commits into the database en masse' do
      expect(Gitlab::Database).to receive(:bulk_insert)
        .with(described_class.table_name, rows)

      subject
    end

    context 'with dates larger than the DB limit' do
      let(:commits) do
        # This commit's date is "Sun Aug 17 07:12:55 292278994 +0000"
        [project.commit('ba3343bc4fa403a8dfbfcab7fc1a8c29ee34bd69')]
      end
      let(:timestamp) { Time.at((1 << 31) - 1) }
      let(:rows) do
        [{
          "message": "Weird commit date\n",
          "authored_date": timestamp,
          "author_name": "Alejandro Rodríguez",
          "author_email": "alejorro70@gmail.com",
          "committed_date": timestamp,
          "committer_name": "Alejandro Rodríguez",
          "committer_email": "alejorro70@gmail.com",
          "merge_request_diff_id": merge_request_diff_id,
          "relative_order": 0,
          "sha": sha_attribute.serialize("ba3343bc4fa403a8dfbfcab7fc1a8c29ee34bd69")
        }]
      end

      it 'uses a sanitized date' do
        expect(Gitlab::Database).to receive(:bulk_insert)
          .with(described_class.table_name, rows)

        subject
      end
    end
  end
end
