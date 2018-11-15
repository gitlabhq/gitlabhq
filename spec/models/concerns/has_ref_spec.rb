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

  describe '#git_ref' do
    subject { pipeline.git_ref }

    context 'when tag is true' do
      let(:pipeline) { create(:ci_pipeline, tag: true) }

      it 'returns a tag ref' do
        is_expected.to start_with(Gitlab::Git::TAG_REF_PREFIX)
      end
    end

    context 'when tag is false' do
      let(:pipeline) { create(:ci_pipeline, tag: false) }

      it 'returns a branch ref' do
        is_expected.to start_with(Gitlab::Git::BRANCH_REF_PREFIX)
      end
    end

    context 'when tag is nil' do
      let(:pipeline) { create(:ci_pipeline, tag: nil) }

      it 'returns a branch ref' do
        is_expected.to start_with(Gitlab::Git::BRANCH_REF_PREFIX)
      end
    end
  end
end
