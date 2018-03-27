require 'spec_helper'

describe Gitlab::GitalyClient::ConflictFilesStitcher do
  describe 'enumeration' do
    it 'combines segregated ConflictFile messages together' do
      target_project = create(:project, :repository)
      target_repository = target_project.repository.raw
      target_gitaly_repository = target_repository.gitaly_repository

      our_path_1 = 'our/path/1'
      their_path_1 = 'their/path/1'
      our_mode_1 = 0744
      commit_oid_1 = 'f00'
      content_1 = 'content of the first file'

      our_path_2 = 'our/path/2'
      their_path_2 = 'their/path/2'
      our_mode_2 = 0600
      commit_oid_2 = 'ba7'
      content_2 = 'content of the second file'

      header_1 = double(repository: target_gitaly_repository, commit_oid: commit_oid_1,
                        our_path: our_path_1, their_path: their_path_1, our_mode: our_mode_1)
      header_2 = double(repository: target_gitaly_repository, commit_oid: commit_oid_2,
                        our_path: our_path_2, their_path: their_path_2, our_mode: our_mode_2)

      messages = [
        double(files: [double(header: header_1), double(header: nil, content: content_1[0..5])]),
        double(files: [double(header: nil, content: content_1[6..-1])]),
        double(files: [double(header: header_2)]),
        double(files: [double(header: nil, content: content_2[0..5]), double(header: nil, content: content_2[6..10])]),
        double(files: [double(header: nil, content: content_2[11..-1])])
      ]

      conflict_files = described_class.new(messages).to_a

      expect(conflict_files.size).to be(2)

      expect(conflict_files[0].content).to eq(content_1)
      expect(conflict_files[0].their_path).to eq(their_path_1)
      expect(conflict_files[0].our_path).to eq(our_path_1)
      expect(conflict_files[0].our_mode).to be(our_mode_1)
      expect(conflict_files[0].repository).to eq(target_repository)
      expect(conflict_files[0].commit_oid).to eq(commit_oid_1)

      expect(conflict_files[1].content).to eq(content_2)
      expect(conflict_files[1].their_path).to eq(their_path_2)
      expect(conflict_files[1].our_path).to eq(our_path_2)
      expect(conflict_files[1].our_mode).to be(our_mode_2)
      expect(conflict_files[1].repository).to eq(target_repository)
      expect(conflict_files[1].commit_oid).to eq(commit_oid_2)
    end
  end
end
