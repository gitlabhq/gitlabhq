# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Badge::Pipeline::Status, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:sha) { project.commit.sha }
  let_it_be(:ref) { 'master' }

  let(:options) { {} }
  let(:badge) { described_class.new(project, ref, opts: options) }

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

  describe '#status' do
    context 'when a pipeline exists' do
      let_it_be_with_reload(:pipeline) do
        create(:ci_pipeline, project: project, sha: sha, ref: ref)
      end

      context 'when it is successful' do
        before do
          pipeline.succeed!
        end

        it { expect(badge.status).to eq 'success' }
      end

      context 'when it is failed' do
        before do
          pipeline.drop!
        end

        it { expect(badge.status).to eq 'failed' }
      end

      context 'when multiple pipelines exist for given sha' do
        let!(:new_pipeline) { create(:ci_pipeline, :success, project: project, sha: sha, ref: ref) }

        before do
          pipeline.drop!
        end

        it 'does not take outdated pipeline into account' do
          expect(badge.status).to eq 'success'
        end
      end

      context 'with skipped pipelines' do
        let_it_be(:skipped_pipeline) { create(:ci_pipeline, :skipped, project: project, sha: sha, ref: ref) }

        before do
          pipeline.succeed!
        end

        context 'when ignored_skipped is set to true' do
          let(:options) { { ignore_skipped: true } }

          it 'uses latest non-skipped status' do
            expect(badge.status).to eq 'success'
          end
        end

        context 'when ignored_skipped is set to false' do
          let(:options) { { ignore_skipped: false } }

          it { expect(badge.status).to eq 'skipped' }
        end
      end
    end

    context 'when a pipeline does not exist' do
      it { expect(badge.status).to eq 'unknown' }
    end
  end
end
