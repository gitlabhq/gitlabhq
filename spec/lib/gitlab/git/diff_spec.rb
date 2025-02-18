# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Git::Diff, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:repository) { project.repository }

  let(:gitaly_diff) do
    Gitlab::GitalyClient::Diff.new(
      from_path: '.gitmodules',
      to_path: '.gitmodules',
      old_mode: 0100644,
      new_mode: 0100644,
      from_id: '0792c58905eff3432b721f8c4a64363d8e28d9ae',
      to_id: 'efd587ccb47caf5f31fc954edb21f0a713d9ecc3',
      overflow_marker: false,
      collapsed: false,
      too_large: false,
      patch: "@@ -4,3 +4,6 @@\n [submodule \"gitlab-shell\"]\n \tpath = gitlab-shell\n \turl = https://github.com/gitlabhq/gitlab-shell.git\n+[submodule \"gitlab-grack\"]\n+\tpath = gitlab-grack\n+\turl = https://gitlab.com/gitlab-org/gitlab-grack.git\n"
    )
  end

  before do
    @raw_diff_hash = {
      diff: <<EOT.gsub(/^ {8}/, "").sub(/\n$/, ""),
        @@ -4,3 +4,6 @@
         [submodule "gitlab-shell"]
         \tpath = gitlab-shell
         \turl = https://github.com/gitlabhq/gitlab-shell.git
        +[submodule "gitlab-grack"]
        +	path = gitlab-grack
        +	url = https://gitlab.com/gitlab-org/gitlab-grack.git

EOT
      new_path: ".gitmodules",
      old_path: ".gitmodules",
      a_mode: '100644',
      b_mode: '100644',
      new_file: false,
      renamed_file: false,
      deleted_file: false,
      too_large: false,
      encoded_file_path: false
    }
  end

  describe '.new' do
    context 'using a Hash' do
      context 'with a small diff' do
        let(:diff) { described_class.new(@raw_diff_hash) }

        it 'initializes the diff' do
          expect(diff.to_hash).to eq(@raw_diff_hash.merge(generated: nil))
        end

        it 'does not prune the diff' do
          expect(diff).not_to be_too_large
        end
      end

      context 'using a diff that is too large' do
        it 'prunes the diff' do
          diff = described_class.new({ diff: 'a' * 204800 })

          expect(diff.diff).to be_empty
          expect(diff).to be_too_large
        end
      end
    end

    context 'using a GitalyClient::Diff' do
      let(:gitaly_diff) do
        Gitlab::GitalyClient::Diff.new(
          to_path: ".gitmodules",
          from_path: ".gitmodules",
          old_mode: 0100644,
          new_mode: 0100644,
          from_id: '357406f3075a57708d0163752905cc1576fceacc',
          to_id: '8e5177d718c561d36efde08bad36b43687ee6bf0',
          patch: raw_patch
        )
      end

      let(:diff) { described_class.new(gitaly_diff) }

      context 'with a small diff' do
        let(:raw_patch) { @raw_diff_hash[:diff] }

        it 'initializes the diff' do
          expect(diff.to_hash).to eq(@raw_diff_hash.merge(generated: nil))
        end

        it 'does not prune the diff' do
          expect(diff).not_to be_too_large
        end
      end

      context 'using a diff that is too large' do
        let(:raw_patch) { 'a' * 204800 }

        it 'prunes the diff' do
          expect(diff.diff).to be_empty
          expect(diff).to be_too_large
        end

        it 'logs the event' do
          expect(Gitlab::Metrics).to receive(:add_event)
            .with(:patch_hard_limit_bytes_hit)

          diff
        end
      end

      context 'using a collapsable diff that is too large' do
        let(:raw_patch) { 'a' * 204800 }

        it 'prunes the diff as a large diff instead of as a collapsed diff' do
          gitaly_diff.too_large = true
          diff = described_class.new(gitaly_diff, expanded: false)

          expect(diff.diff).to be_empty
          expect(diff).to be_too_large
          expect(diff).not_to be_collapsed
        end
      end

      context 'when the patch passed is not UTF-8-encoded' do
        let(:raw_patch) { @raw_diff_hash[:diff].encode(Encoding::ASCII_8BIT) }

        it 'encodes diff patch to UTF-8' do
          expect(diff.diff).to be_utf8
        end
      end

      context 'using a diff that it too large but collecting all paths' do
        let(:gitaly_diff) do
          Gitlab::GitalyClient::Diff.new(
            from_path: '.gitmodules',
            to_path: '.gitmodules',
            old_mode: 0100644,
            new_mode: 0100644,
            from_id: '0792c58905eff3432b721f8c4a64363d8e28d9ae',
            to_id: 'efd587ccb47caf5f31fc954edb21f0a713d9ecc3',
            overflow_marker: true,
            collapsed: false,
            too_large: false,
            patch: ''
          )
        end

        let(:diff) { described_class.new(gitaly_diff) }

        it 'is already pruned and collapsed but not too large' do
          expect(diff.diff).to be_empty
          expect(diff).not_to be_too_large
          expect(diff).to be_collapsed
        end
      end

      context 'when the file is set as generated' do
        let(:diff) { described_class.new(gitaly_diff, generated: true, expanded: expanded) }
        let(:raw_patch) { 'some text' }

        context 'when expanded is set to false' do
          let(:expanded) { false }

          it 'will be marked as generated and collapsed' do
            expect(diff).to be_generated
            expect(diff).to be_collapsed
            expect(diff.diff).to be_empty
          end
        end

        context 'when expanded is set to true' do
          let(:expanded) { true }

          it 'will still be marked as generated, but not as collapsed' do
            expect(diff).to be_generated
            expect(diff).not_to be_collapsed
            expect(diff.diff).not_to be_empty
          end
        end
      end

      context 'when the file path is encoded and cleaned up' do
        let(:gitaly_diff) do
          Gitlab::GitalyClient::Diff.new(
            from_path: "\x90.gitmodules",
            to_path: "\x90.gitmodules",
            old_mode: 0100644,
            new_mode: 0100644,
            from_id: '0792c58905eff3432b721f8c4a64363d8e28d9ae',
            to_id: 'efd587ccb47caf5f31fc954edb21f0a713d9ecc3'
          )
        end

        let(:diff) { described_class.new(gitaly_diff) }

        it 'is flagged with encoded_file_path' do
          expect(diff.old_path).to eq(".gitmodules")
          expect(diff.new_path).to eq(".gitmodules")
          expect(diff.encoded_file_path).to eq(true)
        end
      end

      context 'when the file path is encoded but not cleaned up' do
        let(:gitaly_diff) do
          Gitlab::GitalyClient::Diff.new(
            from_path: "\xE3\x83\x86\xE3\x82\xB9\xE3\x83\x88",
            to_path: "\xE3\x83\x86\xE3\x82\xB9\xE3\x83\x88",
            old_mode: 0100644,
            new_mode: 0100644,
            from_id: '0792c58905eff3432b721f8c4a64363d8e28d9ae',
            to_id: 'efd587ccb47caf5f31fc954edb21f0a713d9ecc3'
          )
        end

        let(:diff) { described_class.new(gitaly_diff) }

        it 'is not flagged with encoded_file_path' do
          expect(diff.old_path).to eq("テスト")
          expect(diff.new_path).to eq("テスト")
          expect(diff.encoded_file_path).to eq(false)
        end
      end
    end

    context 'using a Gitaly::CommitDelta' do
      let(:commit_delta) do
        Gitaly::CommitDelta.new(
          to_path: ".gitmodules",
          from_path: ".gitmodules",
          old_mode: 0100644,
          new_mode: 0100644,
          from_id: '357406f3075a57708d0163752905cc1576fceacc',
          to_id: '8e5177d718c561d36efde08bad36b43687ee6bf0'
        )
      end

      let(:diff) { described_class.new(commit_delta) }

      it 'initializes the diff' do
        expect(diff.to_hash).to eq(@raw_diff_hash.merge(diff: '', generated: nil))
      end

      it 'is not too large' do
        expect(diff).not_to be_too_large
      end

      it 'has an empty diff' do
        expect(diff.diff).to be_empty
      end

      it 'is not a binary' do
        expect(diff).not_to have_binary_notice
      end
    end

    context 'when diff contains invalid characters' do
      let(:bad_string) { [0xae].pack("C*") }
      let(:bad_string_two) { [0x89].pack("C*") }
      let(:bad_string_three) { "@@ -1,5 +1,6 @@\n \xFF\xFE#\x00l\x00a\x00n\x00g\x00u\x00" }

      let(:diff) { described_class.new(@raw_diff_hash.merge({ diff: bad_string })) }
      let(:diff_two) { described_class.new(@raw_diff_hash.merge({ diff: bad_string_two })) }
      let(:diff_three) { described_class.new(@raw_diff_hash.merge({ diff: bad_string_three })) }

      context 'when replace_invalid_utf8_chars is true' do
        it 'will convert invalid characters and not cause an encoding error' do
          expect(diff.diff).to include(Gitlab::EncodingHelper::UNICODE_REPLACEMENT_CHARACTER)
          expect(diff_two.diff).to include(Gitlab::EncodingHelper::UNICODE_REPLACEMENT_CHARACTER)
          expect(diff_three.diff).to include(Gitlab::EncodingHelper::UNICODE_REPLACEMENT_CHARACTER)

          expect { Oj.dump(diff) }.not_to raise_error
          expect { Oj.dump(diff_two) }.not_to raise_error
          expect { Oj.dump(diff_three) }.not_to raise_error
        end

        context 'when the diff is binary' do
          let(:project) { create(:project, :repository) }

          it 'will not try to replace characters' do
            expect(Gitlab::EncodingHelper).not_to receive(:encode_utf8_with_replacement_character?)
            expect(binary_diff(project).diff).not_to be_empty
          end
        end
      end

      context 'when replace_invalid_utf8_chars is false' do
        let(:not_replaced_diff) { described_class.new(@raw_diff_hash.merge({ diff: bad_string, replace_invalid_utf8_chars: false })) }
        let(:not_replaced_diff_two) { described_class.new(@raw_diff_hash.merge({ diff: bad_string_two, replace_invalid_utf8_chars: false })) }

        it 'will not try to convert invalid characters' do
          expect(Gitlab::EncodingHelper).not_to receive(:encode_utf8_with_replacement_character?)
        end
      end
    end
  end

  describe 'straight diffs' do
    let(:options) { { straight: true } }
    let(:diffs) { described_class.between(repository, 'feature', 'master', options) }

    it 'has the correct size' do
      expect(diffs.size).to eq(21)
    end

    context 'diff' do
      it 'is an instance of Diff' do
        expect(diffs.first).to be_kind_of(described_class)
      end

      it 'has the correct new_path' do
        expect(diffs.first.new_path).to eq('.DS_Store')
      end

      it 'has the correct diff' do
        expect(diffs.first.diff).to include('Binary files /dev/null and b/.DS_Store differ')
      end
    end
  end

  describe '.between' do
    let(:diffs) { described_class.between(repository, 'feature', 'master') }

    subject { diffs }

    it { is_expected.to be_kind_of Gitlab::Git::DiffCollection }

    describe '#size' do
      subject { super().size }

      it { is_expected.to eq(1) }
    end

    context 'diff' do
      subject { diffs.first }

      it { is_expected.to be_kind_of described_class }

      describe '#new_path' do
        subject { super().new_path }

        it { is_expected.to eq('files/ruby/feature.rb') }
      end

      describe '#diff' do
        subject { super().diff }

        it { is_expected.to include '+class Feature' }
      end
    end
  end

  describe '.filter_diff_options' do
    let(:options) { { max_files: 100, invalid_opt: true, offset_index: 10 } }

    context "without default options" do
      let(:filtered_options) { described_class.filter_diff_options(options) }

      it "filters invalid options" do
        expect(filtered_options).not_to have_key(:invalid_opt)
      end
    end

    context "with default options" do
      let(:filtered_options) do
        default_options = { max_files: 5, bad_opt: 1, ignore_whitespace_change: true }
        described_class.filter_diff_options(options, default_options)
      end

      it "filters invalid options" do
        expect(filtered_options).not_to have_key(:invalid_opt)
        expect(filtered_options).not_to have_key(:bad_opt)
      end

      it "merges with default options" do
        expect(filtered_options).to have_key(:ignore_whitespace_change)
      end

      it "overrides default options" do
        expect(filtered_options).to have_key(:max_files)
        expect(filtered_options[:max_files]).to eq(100)
      end
    end
  end

  describe '#json_safe_diff' do
    let(:project) { create(:project, :repository) }

    it 'fake binary message when it detects binary' do
      diff_message = "Binary files files/images/icn-time-tracking.pdf and files/images/icn-time-tracking.pdf differ\n"

      diff = binary_diff(project)
      expect(diff.diff).not_to be_empty
      expect(diff.json_safe_diff).to eq(diff_message)
    end

    it 'leave non-binary diffs as-is' do
      diff = described_class.new(gitaly_diff)

      expect(diff.json_safe_diff).to eq(diff.diff)
    end
  end

  describe '#unidiff' do
    let_it_be(:project) { create(:project, :empty_repo) }
    let_it_be(:repository) { project.repository }
    let_it_be(:user) { project.first_owner }

    let(:commits) { repository.commits('master', limit: 10) }
    let(:diffs) { commits.map(&:diffs).map(&:diffs).flat_map(&:to_a).reverse }

    before_all do
      create_commit(
        project,
        user,
        commit_message: "Create file",
        actions: [{ action: 'create', content: 'foo', file_path: 'a.txt' }]
      )

      create_commit(
        project,
        user,
        commit_message: "Update file",
        actions: [{ action: 'update', content: 'foo2', file_path: 'a.txt' }]
      )

      create_commit(
        project,
        user,
        commit_message: "Rename file without change",
        actions: [{ action: 'move', previous_path: 'a.txt', file_path: 'b.txt' }]
      )

      create_commit(
        project,
        user,
        commit_message: "Rename file with change",
        actions: [{ action: 'move', content: 'foo3', previous_path: 'b.txt', file_path: 'c.txt' }]
      )

      create_commit(
        project,
        user,
        commit_message: "Delete file",
        actions: [{ action: 'delete', file_path: 'c.txt' }]
      )

      create_commit(
        project,
        user,
        commit_message: "Create empty file",
        actions: [{ action: 'create', file_path: 'empty.txt' }]
      )

      create_commit(
        project,
        user,
        commit_message: "Create binary file",
        actions: [{ action: 'create', content: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABAQMAAAAl21bKAAAAA1BMVEUAAACnej3aAAAAAXRSTlMAQObYZgAAAApJREFUCNdjYAAAAAIAAeIhvDMAAAAASUVORK5CYII=', file_path: 'test%2Ebin', encoding: 'base64' }]
      )
    end

    context 'when file was created' do
      it 'returns a correct header' do
        diff = diffs[0]

        expect(diff.unidiff).to start_with("--- /dev/null\n+++ b/a.txt\n")
      end
    end

    context 'when file was changed' do
      it 'returns a correct header' do
        diff = diffs[1]

        expect(diff.unidiff).to start_with("--- a/a.txt\n+++ b/a.txt\n")
      end
    end

    context 'when file was moved without content change' do
      it 'returns an empty header' do
        diff = diffs[2]

        expect(diff.unidiff).to eq('')
      end
    end

    context 'when file was moved with content change' do
      it 'returns a correct header' do
        expect(diffs[3].unidiff).to start_with("--- /dev/null\n+++ b/c.txt\n")
        expect(diffs[4].unidiff).to start_with("--- a/b.txt\n+++ /dev/null\n")
      end
    end

    context 'when file was deleted' do
      it 'returns a correct header' do
        diff = diffs[5]

        expect(diff.unidiff).to start_with("--- a/c.txt\n+++ /dev/null\n")
      end
    end

    context 'when empty file was created' do
      it 'returns an empty header' do
        diff = diffs[6]

        expect(diff.unidiff).to eq('')
      end
    end

    context 'when file is binary' do
      it 'returns a binary files message' do
        diff = diffs[7]

        expect(diff.unidiff).to eq("Binary files /dev/null and b/test%2Ebin differ\n")
      end
    end
  end

  describe '#submodule?' do
    let(:gitaly_submodule_diff) do
      Gitlab::GitalyClient::Diff.new(
        from_path: 'gitlab-grack',
        to_path: 'gitlab-grack',
        old_mode: 0,
        new_mode: 57344,
        from_id: '0000000000000000000000000000000000000000',
        to_id: '645f6c4c82fd3f5e06f67134450a570b795e55a6',
        overflow_marker: false,
        collapsed: false,
        too_large: false,
        patch: "@@ -0,0 +1 @@\n+Subproject commit 645f6c4c82fd3f5e06f67134450a570b795e55a6\n"
      )
    end

    it { expect(described_class.new(gitaly_diff).submodule?).to eq(false) }
    it { expect(described_class.new(gitaly_submodule_diff).submodule?).to eq(true) }
  end

  describe '#line_count' do
    let(:diff) { described_class.new(gitaly_diff) }

    it 'returns the correct number of lines' do
      expect(diff.line_count).to eq(7)
    end
  end

  describe "#diff_bytesize" do
    let(:diff) { described_class.new(gitaly_diff) }

    it "returns the size of the diff in bytes" do
      expect(diff.diff_bytesize).to eq(diff.diff.bytesize)
    end
  end

  describe '#too_large?' do
    it 'returns true for a diff that is too large' do
      diff = described_class.new({ diff: 'a' * 204800 })

      expect(diff.too_large?).to eq(true)
    end

    it 'returns false for a diff that is small enough' do
      diff = described_class.new({ diff: 'a' })

      expect(diff.too_large?).to eq(false)
    end

    it 'returns true for a diff that was explicitly marked as being too large' do
      diff = described_class.new({ diff: 'a' })

      diff.too_large!

      expect(diff.too_large?).to eq(true)
    end
  end

  describe '#collapsed?' do
    it 'returns false by default even on quite big diff' do
      diff = described_class.new({ diff: 'a' * 20480 })

      expect(diff).not_to be_collapsed
    end

    it 'returns false by default for a diff that is small enough' do
      diff = described_class.new({ diff: 'a' })

      expect(diff).not_to be_collapsed
    end

    it 'returns true for a diff that was explicitly marked as being collapsed' do
      diff = described_class.new({ diff: 'a' })

      diff.collapse!

      expect(diff).to be_collapsed
    end
  end

  describe '#collapsed?' do
    it 'returns true for a diff that is quite large' do
      diff = described_class.new({ diff: 'a' * 20480 }, expanded: false)

      expect(diff).to be_collapsed
    end

    it 'returns false for a diff that is small enough' do
      diff = described_class.new({ diff: 'a' }, expanded: false)

      expect(diff).not_to be_collapsed
    end
  end

  describe '#collapse!' do
    it 'prunes the diff' do
      diff = described_class.new({ diff: "foo\nbar" })

      diff.collapse!

      expect(diff.diff).to eq('')
      expect(diff.line_count).to eq(0)
    end
  end

  def binary_diff(project)
    # rugged will not detect this as binary, but we can fake it
    described_class.between(project.repository, 'add-pdf-text-binary', 'add-pdf-text-binary^').first
  end

  def create_commit(project, user, params)
    params = { start_branch: 'master', branch_name: 'master' }.merge(params)
    Files::MultiService.new(project, user, params).execute.fetch(:result)
  end
end
