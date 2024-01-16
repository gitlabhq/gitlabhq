# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Git::ChangedPath do
  subject(:changed_path) { described_class.new(path: path, status: status, old_mode: old_mode, new_mode: new_mode) }

  let(:path) { 'test_path' }
  let(:status) { :MODIFIED }
  let(:old_mode) { '100644' }
  let(:new_mode) { '100644' }

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
end
