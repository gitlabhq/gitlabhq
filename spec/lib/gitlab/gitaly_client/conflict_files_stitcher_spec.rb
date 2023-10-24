# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::ConflictFilesStitcher do
  let_it_be(:target_project) { create(:project, :repository) }
  let_it_be(:target_repository) { target_project.repository.raw }
  let_it_be(:target_gitaly_repository) { target_repository.gitaly_repository }

  describe 'enumeration' do
    it 'combines segregated ConflictFile messages together' do
      ancestor_path_1 = 'ancestor/path/1'
      our_path_1 = 'our/path/1'
      their_path_1 = 'their/path/1'
      our_mode_1 = 0744
      commit_oid_1 = 'f00'
      content_1 = 'content of the first file'

      ancestor_path_2 = 'ancestor/path/2'
      our_path_2 = 'our/path/2'
      their_path_2 = 'their/path/2'
      our_mode_2 = 0600
      commit_oid_2 = 'ba7'
      content_2 = 'content of the second file'

      header_1 = double(
        repository: target_gitaly_repository,
        commit_oid: commit_oid_1,
        ancestor_path: ancestor_path_1,
        our_path: our_path_1,
        their_path: their_path_1,
        our_mode: our_mode_1
      )

      header_2 = double(
        repository: target_gitaly_repository,
        commit_oid: commit_oid_2,
        ancestor_path: ancestor_path_2,
        our_path: our_path_2,
        their_path: their_path_2,
        our_mode: our_mode_2
      )

      messages = [
        double(files: [double(header: header_1), double(header: nil, content: content_1[0..5])]),
        double(files: [double(header: nil, content: content_1[6..])]),
        double(files: [double(header: header_2)]),
        double(files: [double(header: nil, content: content_2[0..5]), double(header: nil, content: content_2[6..10])]),
        double(files: [double(header: nil, content: content_2[11..])])
      ]

      conflict_files = described_class.new(messages, target_repository.gitaly_repository).to_a

      expect(conflict_files.size).to be(2)

      expect(conflict_files[0].content).to eq(content_1)
      expect(conflict_files[0].ancestor_path).to eq(ancestor_path_1)
      expect(conflict_files[0].their_path).to eq(their_path_1)
      expect(conflict_files[0].our_path).to eq(our_path_1)
      expect(conflict_files[0].our_mode).to be(our_mode_1)
      expect(conflict_files[0].repository).to eq(target_repository)
      expect(conflict_files[0].commit_oid).to eq(commit_oid_1)

      expect(conflict_files[1].content).to eq(content_2)
      expect(conflict_files[1].ancestor_path).to eq(ancestor_path_2)
      expect(conflict_files[1].their_path).to eq(their_path_2)
      expect(conflict_files[1].our_path).to eq(our_path_2)
      expect(conflict_files[1].our_mode).to be(our_mode_2)
      expect(conflict_files[1].repository).to eq(target_repository)
      expect(conflict_files[1].commit_oid).to eq(commit_oid_2)
    end

    it 'handles non-latin character names' do
      ancestor_path_1_utf8 = "ancestor/テスト.txt"
      our_path_1_utf8 = "our/テスト.txt"
      their_path_1_utf8 = "their/テスト.txt"

      ancestor_path_1 = String.new('ancestor/テスト.txt', encoding: Encoding::US_ASCII)
      our_path_1 = String.new('our/テスト.txt', encoding: Encoding::US_ASCII)
      their_path_1 = String.new('their/テスト.txt', encoding: Encoding::US_ASCII)
      our_mode_1 = 0744
      commit_oid_1 = 'f00'
      content_1 = 'content of the first file'

      header_1 = double(
        repository: target_gitaly_repository,
        commit_oid: commit_oid_1,
        ancestor_path: ancestor_path_1.dup,
        our_path: our_path_1.dup,
        their_path: their_path_1.dup,
        our_mode: our_mode_1
      )

      messages = [
        double(files: [double(header: header_1), double(header: nil, content: content_1[0..5])]),
        double(files: [double(header: nil, content: content_1[6..])])
      ]

      conflict_files = described_class.new(messages, target_repository.gitaly_repository).to_a

      expect(conflict_files.size).to be(1)

      expect(conflict_files[0].content).to eq(content_1)
      expect(conflict_files[0].ancestor_path).to eq(ancestor_path_1_utf8)
      expect(conflict_files[0].their_path).to eq(their_path_1_utf8)
      expect(conflict_files[0].our_path).to eq(our_path_1_utf8)
      expect(conflict_files[0].our_mode).to be(our_mode_1)
      expect(conflict_files[0].repository).to eq(target_repository)
      expect(conflict_files[0].commit_oid).to eq(commit_oid_1)

      # Doesn't equal the ASCII version
      expect(conflict_files[0].ancestor_path).not_to eq(ancestor_path_1)
      expect(conflict_files[0].their_path).not_to eq(their_path_1)
      expect(conflict_files[0].our_path).not_to eq(our_path_1)
    end
  end
end
