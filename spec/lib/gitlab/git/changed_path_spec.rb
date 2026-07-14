# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Git::ChangedPath, feature_category: :source_code_management do
  subject(:changed_path) do
    described_class.new(
      path: path,
      status: status,
      old_mode: old_mode,
      new_mode: new_mode,
      old_blob_id: old_blob_id,
      new_blob_id: new_blob_id,
      commit_id: commit_id
    )
  end

  let(:path) { 'test_path' }
  let(:status) { :MODIFIED }
  let(:old_mode) { '100644' }
  let(:new_mode) { '100644' }
  let(:old_blob_id) { '0000000000000000000000000000000000000000' }
  let(:new_blob_id) { '645f6c4c82fd3f5e06f67134450a570b795e55a6' }
  let(:commit_id) { '0b4bc9a49b562e85de7cc9e834518ea6828729b9' }

  describe '#new_file?' do
    subject(:new_file?) { changed_path.new_file? }

    context 'when it is a new file' do
      let(:status) { :ADDED }

      it 'returns true' do
        expect(new_file?).to eq(true)
      end
    end

    context 'when it is not a new file' do
      it 'returns false' do
        expect(new_file?).to eq(false)
      end
    end
  end

  describe '#deleted_file?' do
    subject(:deleted_file?) { changed_path.deleted_file? }

    it { is_expected.to be_falsey }

    context 'when it is a deleted file' do
      let(:status) { :DELETED }

      it { is_expected.to be_truthy }
    end
  end

  describe '#renamed_file?' do
    subject(:renamed_file?) { changed_path.renamed_file? }

    it { is_expected.to be_falsey }

    context 'when it is a renamed file' do
      let(:status) { :RENAMED }

      it { is_expected.to be_truthy }
    end
  end

  describe '#modified_file?' do
    subject(:modified_file?) { changed_path.modified_file? }

    it { is_expected.to be_truthy }
  end

  describe '#submodule_change?' do
    subject(:submodule_change?) { changed_path.submodule_change? }

    context 'with a regular file change' do
      it { is_expected.to eq false }
    end

    context 'with a submodule addition' do
      let(:status) { :ADDED }
      let(:old_mode) { '0' }
      let(:new_mode) { '160000' }

      it { is_expected.to eq true }
    end

    context 'with a submodule deletion' do
      let(:status) { :MODIFIED }
      let(:old_mode) { '160000' }
      let(:new_mode) { '0' }

      it { is_expected.to eq true }
    end
  end

  describe '.from_diff' do
    let(:new_file) { false }
    let(:deleted_file) { false }
    let(:renamed_file) { false }
    let(:old_path) { 'old_foo.rb' }

    let(:diff) do
      instance_double(
        Gitlab::Git::Diff,
        new_file?: new_file, deleted_file?: deleted_file, renamed_file?: renamed_file,
        new_path: 'foo.rb', old_path: old_path, a_mode: '100644', b_mode: '100755'
      )
    end

    subject(:from_diff) { described_class.from_diff(diff) }

    it 'maps the diff metadata onto a changed path' do
      expect(from_diff).to have_attributes(
        path: 'foo.rb',
        old_path: 'old_foo.rb',
        old_mode: '100644',
        new_mode: '100755',
        status: :MODIFIED
      )
    end

    context 'when the diff is a new file' do
      let(:new_file) { true }
      let(:old_path) { '' }

      it { is_expected.to be_new_file }

      it 'falls back to the new path when the diff has a blank old path' do
        expect(from_diff.old_path).to eq('foo.rb')
      end
    end

    context 'when the diff is a deleted file' do
      let(:deleted_file) { true }

      it { is_expected.to be_deleted_file }
    end

    context 'when the diff is a renamed file' do
      let(:renamed_file) { true }

      it { is_expected.to be_renamed_file }
    end
  end
end
