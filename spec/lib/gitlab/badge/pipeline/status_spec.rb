require 'spec_helper'

describe Gitlab::Badge::Pipeline::Status do
  let(:project) { create(:project, :repository) }
  let(:sha) { project.commit.sha }
  let(:branch) { 'master' }
  let(:badge) { described_class.new(project, branch) }

  describe '#entity' do
    it 'always says pipeline' do
      expect(badge.entity).to eq 'pipeline'
    end
  end

  describe '#template' do
    it 'returns badge template' do
      expect(badge.template.key_text).to eq 'pipeline'
    end
  end

  describe '#metadata' do
    it 'returns badge metadata' do
      expect(badge.metadata.image_url).to include 'badges/master/pipeline.svg'
    end
  end

  context 'pipeline exists' do
    let!(:pipeline) { create_pipeline(project, sha, branch) }

    context 'pipeline success' do
      before do
        pipeline.success!
      end

      describe '#status' do
        it 'is successful' do
          expect(badge.status).to eq 'success'
        end
      end
    end

    context 'pipeline failed' do
      before do
        pipeline.drop!
      end

      describe '#status' do
        it 'failed' do
          expect(badge.status).to eq 'failed'
        end
      end
    end

    context 'when outdated pipeline for given ref exists' do
      before do
        pipeline.success!

        old_pipeline = create_pipeline(project, '11eeffdd', branch)
        old_pipeline.drop!
      end

      it 'does not take outdated pipeline into account' do
        expect(badge.status).to eq 'success'
      end
    end

    context 'when multiple pipelines exist for given sha' do
      before do
        pipeline.drop!

        new_pipeline = create_pipeline(project, sha, branch)
        new_pipeline.success!
      end

      it 'does not take outdated pipeline into account' do
        expect(badge.status).to eq 'success'
      end
    end
  end

  context 'build does not exist' do
    describe '#status' do
      it 'is unknown' do
        expect(badge.status).to eq 'unknown'
      end
    end
  end

  def create_pipeline(project, sha, branch)
    pipeline = create(:ci_empty_pipeline,
                      project: project,
                      sha: sha,
                      ref: branch)

    create(:ci_build, pipeline: pipeline, stage: 'notify')
  end
end
