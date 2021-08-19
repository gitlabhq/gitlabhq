# frozen_string_literal: true

RSpec.shared_examples ::Security::JobsFinder do |default_job_types|
  let(:pipeline) { create(:ci_pipeline) }

  describe '#new' do
    it "does not get initialized for unsupported job types" do
      expect { described_class.new(pipeline: pipeline, job_types: [:abcd]) }.to raise_error(
        ArgumentError,
        "job_types must be from the following: #{default_job_types}"
      )
    end
  end

  describe '#execute' do
    let(:finder) { described_class.new(pipeline: pipeline) }

    subject { finder.execute }

    shared_examples 'JobsFinder core functionality' do
      context 'when the pipeline has no jobs' do
        it { is_expected.to be_empty }
      end

      context 'when the pipeline has no Secure jobs' do
        before do
          create(:ci_build, pipeline: pipeline)
        end

        it { is_expected.to be_empty }
      end

      context 'when the pipeline only has jobs without report artifacts' do
        before do
          create(:ci_build, pipeline: pipeline, options: { artifacts: { file: 'test.file' } })
        end

        it { is_expected.to be_empty }
      end

      context 'when the pipeline only has jobs with reports unrelated to Secure products' do
        before do
          create(:ci_build, pipeline: pipeline, options: { artifacts: { reports: { file: 'test.file' } } })
        end

        it { is_expected.to be_empty }
      end

      context 'when the pipeline only has jobs with reports with paths similar but not identical to Secure reports' do
        before do
          create(:ci_build, pipeline: pipeline, options: { artifacts: { reports: { file: 'report:sast:result.file' } } })
        end

        it { is_expected.to be_empty }
      end

      context 'when there is more than one pipeline' do
        let(:job_type) { default_job_types.first }
        let!(:build) { create(:ci_build, job_type, pipeline: pipeline) }

        before do
          create(:ci_build, job_type, pipeline: create(:ci_pipeline))
        end

        it 'returns jobs associated with provided pipeline' do
          is_expected.to eq([build])
        end
      end
    end

    it_behaves_like 'JobsFinder core functionality'
  end
end
