# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::UnlockArtifactsService do
  describe '#execute' do
    subject(:execute) { described_class.new(pipeline.project, pipeline.user).execute(ci_ref, before_pipeline) }

    before do
      stub_const("#{described_class}::BATCH_SIZE", 1)
    end

    [true, false].each do |tag|
      context "when tag is #{tag}" do
        let(:ref) { 'master' }
        let(:ref_path) { tag ? "#{::Gitlab::Git::TAG_REF_PREFIX}#{ref}" : "#{::Gitlab::Git::BRANCH_REF_PREFIX}#{ref}" }
        let(:ci_ref) { create(:ci_ref, ref_path: ref_path) }

        let!(:old_unlocked_pipeline) { create(:ci_pipeline, ref: ref, tag: tag, project: ci_ref.project, locked: :unlocked) }
        let!(:older_pipeline) { create(:ci_pipeline, ref: ref, tag: tag, project: ci_ref.project, locked: :artifacts_locked) }
        let!(:older_ambiguous_pipeline) { create(:ci_pipeline, ref: ref, tag: !tag, project: ci_ref.project, locked: :artifacts_locked) }
        let!(:pipeline) { create(:ci_pipeline, ref: ref, tag: tag, project: ci_ref.project, locked: :artifacts_locked) }
        let!(:child_pipeline) { create(:ci_pipeline, ref: ref, tag: tag, project: ci_ref.project, locked: :artifacts_locked) }
        let!(:newer_pipeline) { create(:ci_pipeline, ref: ref, tag: tag, project: ci_ref.project, locked: :artifacts_locked) }
        let!(:other_ref_pipeline) { create(:ci_pipeline, ref: 'other_ref', tag: tag, project: ci_ref.project, locked: :artifacts_locked) }

        before do
          create(:ci_sources_pipeline,
                 source_job: create(:ci_build, pipeline: pipeline),
                 source_project: ci_ref.project,
                 pipeline: child_pipeline,
                 project: ci_ref.project)
        end

        context 'when running on a ref before a pipeline' do
          let(:before_pipeline) { pipeline }

          it 'unlocks artifacts from older pipelines' do
            expect { execute }.to change { older_pipeline.reload.locked }.from('artifacts_locked').to('unlocked')
          end

          it 'does not unlock artifacts for tag or branch with same name as ref' do
            expect { execute }.not_to change { older_ambiguous_pipeline.reload.locked }.from('artifacts_locked')
          end

          it 'does not unlock artifacts from newer pipelines' do
            expect { execute }.not_to change { newer_pipeline.reload.locked }.from('artifacts_locked')
          end

          it 'does not lock artifacts from old unlocked pipelines' do
            expect { execute }.not_to change { old_unlocked_pipeline.reload.locked }.from('unlocked')
          end

          it 'does not unlock artifacts from the same pipeline' do
            expect { execute }.not_to change { pipeline.reload.locked }.from('artifacts_locked')
          end

          it 'does not unlock artifacts for other refs' do
            expect { execute }.not_to change { other_ref_pipeline.reload.locked }.from('artifacts_locked')
          end

          it 'does not unlock artifacts for child pipeline' do
            expect { execute }.not_to change { child_pipeline.reload.locked }.from('artifacts_locked')
          end
        end

        context 'when running on just the ref' do
          let(:before_pipeline) { nil }

          it 'unlocks artifacts from older pipelines' do
            expect { execute }.to change { older_pipeline.reload.locked }.from('artifacts_locked').to('unlocked')
          end

          it 'unlocks artifacts from newer pipelines' do
            expect { execute }.to change { newer_pipeline.reload.locked }.from('artifacts_locked').to('unlocked')
          end

          it 'unlocks artifacts from the same pipeline' do
            expect { execute }.to change { pipeline.reload.locked }.from('artifacts_locked').to('unlocked')
          end

          it 'does not unlock artifacts for tag or branch with same name as ref' do
            expect { execute }.not_to change { older_ambiguous_pipeline.reload.locked }.from('artifacts_locked')
          end

          it 'does not lock artifacts from old unlocked pipelines' do
            expect { execute }.not_to change { old_unlocked_pipeline.reload.locked }.from('unlocked')
          end

          it 'does not unlock artifacts for other refs' do
            expect { execute }.not_to change { other_ref_pipeline.reload.locked }.from('artifacts_locked')
          end
        end
      end
    end
  end
end
