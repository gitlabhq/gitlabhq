require 'spec_helper'

describe Gitlab::Badge::Coverage::Report do
  let(:project) { create(:project) }
  let(:job_name) { nil }

  let(:badge) do
    described_class.new(project, 'master', job_name)
  end

  describe '#entity' do
    it 'describes a coverage' do
      expect(badge.entity).to eq 'coverage'
    end
  end

  describe '#metadata' do
    it 'returns correct metadata' do
      expect(badge.metadata.image_url).to include 'coverage.svg'
    end
  end

  describe '#template' do
    it 'returns correct template' do
      expect(badge.template.key_text).to eq 'coverage'
    end
  end

  shared_examples 'unknown coverage report' do
    context 'particular job specified' do
      let(:job_name) { '' }

      it 'returns nil' do
        expect(badge.status).to be_nil
      end
    end

    context 'particular job not specified' do
      let(:job_name) { nil }

      it 'returns nil' do
        expect(badge.status).to be_nil
      end
    end
  end

  context 'pipeline exists' do
    let!(:pipeline) do
      create(:ci_pipeline, project: project,
                           sha: project.commit.id,
                           ref: 'master')
    end

    context 'builds exist' do
      before do
        create(:ci_build, name: 'first', pipeline: pipeline, coverage: 40)
        create(:ci_build, pipeline: pipeline, coverage: 60)
      end

      context 'particular job specified' do
        let(:job_name) { 'first' }

        it 'returns coverage for the particular job' do
          expect(badge.status).to eq 40
        end
      end

      context 'particular job not specified' do
        let(:job_name) { '' }

        it 'returns arithemetic mean for the pipeline' do
          expect(badge.status).to eq 50
        end
      end
    end

    context 'builds do not exist' do
      it_behaves_like 'unknown coverage report'

      context 'particular job specified' do
        let(:job_name) { 'nonexistent' }

        it 'retruns nil' do
          expect(badge.status).to be_nil
        end
      end
    end
  end

  context 'pipeline does not exist' do
    it_behaves_like 'unknown coverage report'
  end
end
