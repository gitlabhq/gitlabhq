require 'spec_helper'

describe Gitlab::Badge::Build::Status do
  let(:project) { create(:project) }
  let(:sha) { project.commit.sha }
  let(:branch) { 'master' }
  let(:badge) { described_class.new(project, branch) }

  describe '#entity' do
    it 'always says build' do
      expect(badge.entity).to eq 'build'
    end
  end

  describe '#template' do
    it 'returns badge template' do
      expect(badge.template.key_text).to eq 'build'
    end
  end

  describe '#metadata' do
    it 'returns badge metadata' do
      expect(badge.metadata.image_url)
        .to include 'badges/master/build.svg'
    end
  end

  context 'build exists' do
    let!(:build) { create_build(project, sha, branch) }

    context 'build success' do
      before { build.success! }

      describe '#status' do
        it 'is successful' do
          expect(badge.status).to eq 'success'
        end
      end
    end

    context 'build failed' do
      before { build.drop! }

      describe '#status' do
        it 'failed' do
          expect(badge.status).to eq 'failed'
        end
      end
    end

    context 'when outdated pipeline for given ref exists' do
      before do
        build.success!

        old_build = create_build(project, '11eeffdd', branch)
        old_build.drop!
      end

      it 'does not take outdated pipeline into account' do
        expect(badge.status).to eq 'success'
      end
    end

    context 'when multiple pipelines exist for given sha' do
      before do
        build.drop!

        new_build = create_build(project, sha, branch)
        new_build.success!
      end

      it 'reports the compound status' do
        expect(badge.status).to eq 'failed'
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

  def create_build(project, sha, branch)
    pipeline = create(:ci_empty_pipeline,
                      project: project,
                      sha: sha,
                      ref: branch)

    create(:ci_build, pipeline: pipeline, stage: 'notify')
  end
end
