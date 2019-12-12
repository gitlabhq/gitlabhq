# frozen_string_literal: true

require "spec_helper"

describe Gitlab::Git::Diff, :seed_helper do
  let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '', 'group/project') }
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
      too_large: false
    }
  end

  describe '.new' do
    context 'using a Hash' do
      context 'with a small diff' do
        let(:diff) { described_class.new(@raw_diff_hash) }

        it 'initializes the diff' do
          expect(diff.to_hash).to eq(@raw_diff_hash)
        end

        it 'does not prune the diff' do
          expect(diff).not_to be_too_large
        end
      end

      context 'using a diff that is too large' do
        it 'prunes the diff' do
          diff = described_class.new(diff: 'a' * 204800)

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
          expect(diff.to_hash).to eq(@raw_diff_hash)
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
    end
  end

  describe 'straight diffs' do
    let(:options) { { straight: true } }
    let(:diffs) { described_class.between(repository, 'feature', 'master', options) }

    it 'has the correct size' do
      expect(diffs.size).to eq(24)
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
    let(:options) { { max_files: 100, invalid_opt: true } }

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
      # Rugged will not detect this as binary, but we can fake it
      diff_message = "Binary files files/images/icn-time-tracking.pdf and files/images/icn-time-tracking.pdf differ\n"
      binary_diff = described_class.between(project.repository, 'add-pdf-text-binary', 'add-pdf-text-binary^').first

      expect(binary_diff.diff).not_to be_empty
      expect(binary_diff.json_safe_diff).to eq(diff_message)
    end

    it 'leave non-binary diffs as-is' do
      diff = described_class.new(gitaly_diff)

      expect(diff.json_safe_diff).to eq(diff.diff)
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
    it 'returns the correct number of lines' do
      diff = described_class.new(gitaly_diff)

      expect(diff.line_count).to eq(7)
    end
  end

  describe '#too_large?' do
    it 'returns true for a diff that is too large' do
      diff = described_class.new(diff: 'a' * 204800)

      expect(diff.too_large?).to eq(true)
    end

    it 'returns false for a diff that is small enough' do
      diff = described_class.new(diff: 'a')

      expect(diff.too_large?).to eq(false)
    end

    it 'returns true for a diff that was explicitly marked as being too large' do
      diff = described_class.new(diff: 'a')

      diff.too_large!

      expect(diff.too_large?).to eq(true)
    end
  end

  describe '#collapsed?' do
    it 'returns false by default even on quite big diff' do
      diff = described_class.new(diff: 'a' * 20480)

      expect(diff).not_to be_collapsed
    end

    it 'returns false by default for a diff that is small enough' do
      diff = described_class.new(diff: 'a')

      expect(diff).not_to be_collapsed
    end

    it 'returns true for a diff that was explicitly marked as being collapsed' do
      diff = described_class.new(diff: 'a')

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
      diff = described_class.new(diff: "foo\nbar")

      diff.collapse!

      expect(diff.diff).to eq('')
      expect(diff.line_count).to eq(0)
    end
  end
end
