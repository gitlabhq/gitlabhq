require 'spec_helper'

describe MergeRequestPresenter do
  describe '#ci_status' do
    let(:resource) { create :merge_request, source_project: project }
    let(:project) { create :project }

    subject { described_class.new(resource).ci_status }

    context 'when no head pipeline' do
      it 'return status using CiService' do
        ci_service = double(MockCiService)
        ci_status = double

        allow(resource.source_project)
          .to receive(:ci_service)
          .and_return(ci_service)

        allow(resource).to receive(:head_pipeline).and_return(nil)

        expect(ci_service).to receive(:commit_status)
          .with(resource.diff_head_sha, resource.source_branch)
          .and_return(ci_status)

        is_expected.to eq(ci_status)
      end
    end

    context 'when head pipeline present' do
      let(:pipeline) { build_stubbed(:ci_pipeline) }

      before do
        allow(resource).to receive(:head_pipeline).and_return(pipeline)
      end

      context 'success with warnings' do
        before do
          allow(pipeline).to receive(:success?) { true }
          allow(pipeline).to receive(:has_warnings?) { true }
        end

        it 'returns "success_with_warnings"' do
          is_expected.to eq('success_with_warnings')
        end
      end

      context 'pipeline HAS status AND its not success with warnings' do
        before do
          allow(pipeline).to receive(:success?) { false }
          allow(pipeline).to receive(:has_warnings?) { false }
        end

        it 'returns pipeline status' do
          is_expected.to eq('pending')
        end
      end

      context 'pipeline has NO status AND its not success with warnings' do
        before do
          allow(pipeline).to receive(:status) { nil }
          allow(pipeline).to receive(:success?) { false }
          allow(pipeline).to receive(:has_warnings?) { false }
        end

        it 'returns "preparing"' do
          is_expected.to eq('preparing')
        end
      end
    end
  end
end
