# frozen_string_literal: true

require 'spec_helper'

describe HasRef do
  describe '#branch?' do
    let(:pipeline) { create(:ci_pipeline) }

    subject { pipeline.branch? }

    context 'is not a tag' do
      before do
        pipeline.tag = false
      end

      it 'return true when tag is set to false' do
        is_expected.to be_truthy
      end
    end

    context 'is not a tag' do
      before do
        pipeline.tag = true
      end

      it 'return false when tag is set to true' do
        is_expected.to be_falsey
      end
    end
  end
end
