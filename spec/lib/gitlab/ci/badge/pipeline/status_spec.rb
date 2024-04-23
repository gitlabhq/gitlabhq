# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Badge::Pipeline::Status do
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

  context 'pipeline exists', :sidekiq_might_not_need_inline do
    let!(:build) { create_pipeline_and_build(project, sha, branch, 2) }

    context 'pipeline success' do
      before do
        build.success!
      end

      describe '#status' do
        it 'is successful' do
          expect(badge.status).to eq 'success'
        end
      end
    end

    context 'pipeline failed' do
      before do
        build.drop!
      end

      describe '#status' do
        it 'failed' do
          expect(badge.status).to eq 'failed'
        end
      end
    end

    context 'when outdated pipeline for given ref exists' do
      before do
        build.success!

        old_build = create_pipeline_and_build(project, '11eeffdd', branch, 1)
        old_build.drop!
      end

      it 'does not take outdated pipeline into account' do
        expect(badge.status).to eq 'success'
      end
    end

    context 'when multiple pipelines exist for given sha' do
      before do
        build.drop!

        new_build = create_pipeline_and_build(project, sha, branch, 3)
        new_build.success!
      end

      it 'does not take outdated pipeline into account' do
        expect(badge.status).to eq 'success'
      end
    end

    context 'when ignored_skipped is set to true' do
      let(:new_badge) { described_class.new(project, branch, opts: { ignore_skipped: true }) }

      before do
        build.skip!
      end

      describe '#status' do
        it 'uses latest non-skipped status' do
          expect(new_badge.status).not_to eq 'skipped'
        end
      end
    end

    context 'when ignored_skipped is set to false' do
      let(:new_badge) { described_class.new(project, branch, opts: { ignore_skipped: false }) }

      before do
        build.skip!
      end

      describe '#status' do
        it 'uses latest status' do
          expect(new_badge.status).to eq 'skipped'
        end
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

  def create_pipeline_and_build(project, sha, branch, id)
    pipeline = create(:ci_empty_pipeline, project: project, sha: sha, ref: branch, id: id)

    create(:ci_build, pipeline: pipeline, stage: 'notify')
  end
end
