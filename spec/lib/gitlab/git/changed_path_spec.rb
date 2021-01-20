# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Git::ChangedPath do
  subject(:changed_path) { described_class.new(path: path, status: status) }

  let(:path) { 'test_path' }

  describe '#new_file?' do
    subject(:new_file?) { changed_path.new_file? }

    context 'when it is a new file' do
      let(:status) { :ADDED }

      it 'returns true' do
        expect(new_file?).to eq(true)
      end
    end

    context 'when it is not a new file' do
      let(:status) { :MODIFIED }

      it 'returns false' do
        expect(new_file?).to eq(false)
      end
    end
  end
end
