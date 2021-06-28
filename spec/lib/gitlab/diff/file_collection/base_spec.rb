# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::FileCollection::Base do
  let(:merge_request) { create(:merge_request) }
  let(:diffable) { merge_request.merge_request_diff }
  let(:diff_options) { {} }

  describe '#overflow?' do
    subject(:overflown) { described_class.new(diffable, project: merge_request.project, diff_options: diff_options).overflow? }

    context 'when it is not overflown' do
      it 'returns false' do
        expect(overflown).to eq(false)
      end
    end

    context 'when it is overflown' do
      let(:diff_options) { { max_files: 1 } }

      it 'returns true' do
        expect(overflown).to eq(true)
      end
    end
  end
end
