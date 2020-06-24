# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::HasRef do
  describe '#branch?' do
    let(:build) { create(:ci_build) }

    subject { build.branch? }

    context 'is not a tag' do
      before do
        build.tag = false
      end

      it 'return true when tag is set to false' do
        is_expected.to be_truthy
      end

      context 'when it was triggered by merge request' do
        let(:merge_request) { create(:merge_request, :with_detached_merge_request_pipeline) }
        let(:pipeline) { merge_request.pipelines_for_merge_request.first }
        let(:build) { create(:ci_build, pipeline: pipeline) }

        it 'returns false' do
          is_expected.to be_falsy
        end
      end
    end

    context 'is not a tag' do
      before do
        build.tag = true
      end

      it 'return false when tag is set to true' do
        is_expected.to be_falsey
      end
    end
  end

  describe '#git_ref' do
    subject { build.git_ref }

    context 'when tag is true' do
      let(:build) { create(:ci_build, tag: true) }

      it 'returns a tag ref' do
        is_expected.to start_with(Gitlab::Git::TAG_REF_PREFIX)
      end
    end

    context 'when tag is false' do
      let(:build) { create(:ci_build, tag: false) }

      it 'returns a branch ref' do
        is_expected.to start_with(Gitlab::Git::BRANCH_REF_PREFIX)
      end
    end

    context 'when tag is nil' do
      let(:build) { create(:ci_build, tag: nil) }

      it 'returns a branch ref' do
        is_expected.to start_with(Gitlab::Git::BRANCH_REF_PREFIX)
      end
    end

    context 'when it is triggered by a merge request' do
      let(:merge_request) { create(:merge_request, :with_detached_merge_request_pipeline) }
      let(:pipeline) { merge_request.pipelines_for_merge_request.first }
      let(:build) { create(:ci_build, tag: false, pipeline: pipeline) }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end
end
