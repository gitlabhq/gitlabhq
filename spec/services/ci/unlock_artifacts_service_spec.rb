# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::UnlockArtifactsService, feature_category: :continuous_integration do
  let_it_be(:ref) { 'master' }
  let_it_be(:project) { create(:project) }
  let_it_be(:tag_ref_path) { "#{::Gitlab::Git::TAG_REF_PREFIX}#{ref}" }
  let_it_be(:ci_ref_tag) { create(:ci_ref, ref_path: tag_ref_path, project: project) }
  let_it_be(:branch_ref_path) { "#{::Gitlab::Git::BRANCH_REF_PREFIX}#{ref}" }
  let_it_be(:ci_ref_branch) { create(:ci_ref, ref_path: branch_ref_path, project: project) }
  let_it_be(:new_ref) { 'new_ref' }
  let_it_be(:new_ref_path) { "#{::Gitlab::Git::BRANCH_REF_PREFIX}#{new_ref}" }
  let_it_be(:new_ci_ref) { create(:ci_ref, ref_path: new_ref_path, project: project) }

  using RSpec::Parameterized::TableSyntax

  where(:tag) do
    [
      [false],
      [true]
    ]
  end

  with_them do
    let(:target_ref) { tag ? ci_ref_tag : ci_ref_branch }
    let(:source_job) { create(:ci_build, pipeline: pipeline) }

    let!(:old_unlocked_pipeline) { create(:ci_pipeline, :with_persisted_artifacts, ref: ref, tag: tag, project: project, locked: :unlocked) }
    let!(:older_pipeline) { create(:ci_pipeline, :with_persisted_artifacts, ref: ref, tag: tag, project: project, locked: :artifacts_locked) }
    let!(:older_ambiguous_pipeline) { create(:ci_pipeline, :with_persisted_artifacts, ref: ref, tag: !tag, project: project, locked: :artifacts_locked) }
    let!(:code_coverage_pipeline) { create(:ci_pipeline, :with_coverage_report_artifact, ref: ref, tag: tag, project: project, locked: :artifacts_locked) }
    let!(:successful_pipeline) { create(:ci_pipeline, :with_persisted_artifacts, ref: ref, tag: tag, project: project, locked: :artifacts_locked) }
    let!(:child_pipeline) { create(:ci_pipeline, :with_persisted_artifacts, ref: ref, tag: tag, child_of: successful_pipeline, project: project, locked: :artifacts_locked) }
    let!(:last_successful_pipeline) { create(:ci_pipeline, :with_persisted_artifacts, ref: ref, tag: tag, project: project, locked: :artifacts_locked) }
    let!(:last_successful_child_pipeline) { create(:ci_pipeline, :with_persisted_artifacts, ref: ref, tag: tag, child_of: last_successful_pipeline, project: project, locked: :artifacts_locked) }
    let!(:older_failed_pipeline) { create(:ci_pipeline, :with_persisted_artifacts, status: :failed, ref: ref, tag: tag, project: project, locked: :artifacts_locked) }
    let!(:latest_failed_pipeline) { create(:ci_pipeline, :with_persisted_artifacts, status: :failed, ref: ref, tag: tag, project: project, locked: :artifacts_locked) }
    let!(:blocked_pipeline) { create(:ci_pipeline, :with_persisted_artifacts, status: :manual, ref: ref, tag: tag, project: project, locked: :artifacts_locked) }
    let!(:other_ref_pipeline) { create(:ci_pipeline, :with_persisted_artifacts, ref: 'other_ref', tag: tag, project: project, locked: :artifacts_locked) }

    before do
      stub_const("#{described_class}::BATCH_SIZE", 1)
    end

    describe '#execute' do
      subject(:execute) { described_class.new(successful_pipeline.project, successful_pipeline.user).execute(target_ref, before_pipeline) }

      context 'when running on a ref before a pipeline' do
        let(:before_pipeline) { successful_pipeline }

        it 'unlocks artifacts from older pipelines' do
          expect { execute }.to change { older_pipeline.reload.locked }.from('artifacts_locked').to('unlocked')
        end

        it 'does not unlock artifacts for tag or branch with same name as ref' do
          expect { execute }.not_to change { older_ambiguous_pipeline.reload.locked }.from('artifacts_locked')
        end

        it 'does not unlock artifacts from newer pipelines' do
          expect { execute }.not_to change { last_successful_pipeline.reload.locked }.from('artifacts_locked')
        end

        it 'does not lock artifacts from old unlocked pipelines' do
          expect { execute }.not_to change { old_unlocked_pipeline.reload.locked }.from('unlocked')
        end

        it 'does not unlock artifacts from the successful pipeline' do
          expect { execute }.not_to change { successful_pipeline.reload.locked }.from('artifacts_locked')
        end

        it 'does not unlock artifacts for other refs' do
          expect { execute }.not_to change { other_ref_pipeline.reload.locked }.from('artifacts_locked')
        end

        it 'does not unlock artifacts for child pipeline' do
          expect { execute }.not_to change { child_pipeline.reload.locked }.from('artifacts_locked')
        end

        it 'unlocks job artifact records' do
          expect { execute }.to change { ::Ci::JobArtifact.artifact_unlocked.count }.from(0).to(2)
        end

        it 'unlocks pipeline artifact records' do
          expect { execute }.to change { ::Ci::PipelineArtifact.artifact_unlocked.count }.from(0).to(1)
        end

        context 'when before_pipeline is a failed pipeline' do
          let(:before_pipeline) { latest_failed_pipeline }

          it 'unlocks artifacts from older failed pipeline' do
            expect { execute }.to change { older_failed_pipeline.reload.locked }.from('artifacts_locked').to('unlocked')
          end

          it 'does not unlock artifact from the latest failed pipeline' do
            expect { execute }.not_to change { latest_failed_pipeline.reload.locked }.from('artifacts_locked')
          end

          it 'does not unlock artifacts from the last successful pipeline' do
            expect { execute }.not_to change { last_successful_pipeline.reload.locked }.from('artifacts_locked')
          end

          it 'does not unlock artifacts from the child of last successful pipeline' do
            expect { execute }.not_to change { last_successful_child_pipeline.reload.locked }.from('artifacts_locked')
          end
        end

        context 'when before_pipeline is a blocked pipeline' do
          let(:before_pipeline) { blocked_pipeline }

          it 'unlocks artifacts from failed pipeline' do
            expect { execute }.to change { latest_failed_pipeline.reload.locked }.from('artifacts_locked').to('unlocked')
          end

          it 'does not unlock artifact from the latest blocked pipeline' do
            expect { execute }.not_to change { blocked_pipeline.reload.locked }.from('artifacts_locked')
          end

          it 'does not unlock artifacts from the last successful pipeline' do
            expect { execute }.not_to change { last_successful_pipeline.reload.locked }.from('artifacts_locked')
          end
        end

        # rubocop:todo RSpec/MultipleMemoizedHelpers
        context 'when the ref has no successful pipeline' do
          let!(:target_ref) { new_ci_ref }
          let!(:failed_pipeline_1) { create(:ci_pipeline, :with_persisted_artifacts, status: :failed, ref: new_ref, project: project, locked: :artifacts_locked) }
          let!(:failed_pipeline_2) { create(:ci_pipeline, :with_persisted_artifacts, status: :failed, ref: new_ref, project: project, locked: :artifacts_locked) }

          let(:before_pipeline) { failed_pipeline_2 }

          it 'unlocks earliest failed pipeline' do
            expect { execute }.to change { failed_pipeline_1.reload.locked }.from('artifacts_locked').to('unlocked')
          end

          it 'does not unlock latest failed pipeline' do
            expect { execute }.not_to change { failed_pipeline_2.reload.locked }.from('artifacts_locked')
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers
      end

      context 'when running on just the ref' do
        let(:before_pipeline) { nil }

        it 'unlocks artifacts from older pipelines' do
          expect { execute }.to change { older_pipeline.reload.locked }.from('artifacts_locked').to('unlocked')
        end

        it 'unlocks artifacts from newer pipelines' do
          expect { execute }.to change { last_successful_pipeline.reload.locked }.from('artifacts_locked').to('unlocked')
        end

        it 'unlocks artifacts from the successful pipeline' do
          expect { execute }.to change { successful_pipeline.reload.locked }.from('artifacts_locked').to('unlocked')
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

        it 'unlocks job artifact records' do
          expect { execute }.to change { ::Ci::JobArtifact.artifact_unlocked.count }.from(0).to(16)
        end

        it 'unlocks pipeline artifact records' do
          expect { execute }.to change { ::Ci::PipelineArtifact.artifact_unlocked.count }.from(0).to(1)
        end
      end
    end

    describe '#unlock_pipelines_query' do
      subject { described_class.new(successful_pipeline.project, successful_pipeline.user).unlock_pipelines_query(target_ref, before_pipeline) }

      context 'when running on a ref before a pipeline' do
        let(:before_pipeline) { successful_pipeline }

        it 'produces the expected SQL string' do
          expect(subject.squish).to eq <<~SQL.squish
            UPDATE
                "ci_pipelines"
            SET
                "locked" = 0
            WHERE
                "ci_pipelines"."id" IN
                    (SELECT
                        "ci_pipelines"."id"
                    FROM
                        "ci_pipelines"
                    WHERE
                        "ci_pipelines"."ci_ref_id" = #{target_ref.id}
                        AND "ci_pipelines"."locked" = 1
                        AND "ci_pipelines"."id" < #{before_pipeline.id}
                        AND "ci_pipelines"."id" NOT IN
                            (WITH RECURSIVE
                                "base_and_descendants"
                            AS
                                ((SELECT
                                    "ci_pipelines".*
                                FROM
                                    "ci_pipelines"
                                WHERE
                                    "ci_pipelines"."id" = #{before_pipeline.id})
                            UNION
                                (SELECT
                                    "ci_pipelines".*
                                FROM
                                    "ci_pipelines",
                                    "base_and_descendants",
                                    "ci_sources_pipelines"
                                WHERE
                                    "ci_sources_pipelines"."pipeline_id" = "ci_pipelines"."id"
                                    AND "ci_sources_pipelines"."source_pipeline_id" = "base_and_descendants"."id"
                                    AND "ci_sources_pipelines"."source_project_id" = "ci_sources_pipelines"."project_id"))
                            SELECT
                                "id"
                            FROM
                                "base_and_descendants"
                            AS
                                "ci_pipelines")
                        AND "ci_pipelines"."id" NOT IN
                            (WITH RECURSIVE
                                "base_and_descendants"
                            AS
                                ((SELECT
                                    "ci_pipelines".*
                                FROM
                                    "ci_pipelines"
                                WHERE
                                    "ci_pipelines"."id" = #{target_ref.last_successful_pipeline.id})
                            UNION
                                (SELECT
                                    "ci_pipelines".*
                                FROM
                                    "ci_pipelines",
                                    "base_and_descendants",
                                    "ci_sources_pipelines"
                                WHERE
                                    "ci_sources_pipelines"."pipeline_id" = "ci_pipelines"."id"
                                    AND "ci_sources_pipelines"."source_pipeline_id" = "base_and_descendants"."id"
                                    AND "ci_sources_pipelines"."source_project_id" = "ci_sources_pipelines"."project_id"))
                            SELECT
                                "id"
                            FROM
                                "base_and_descendants"
                            AS
                                "ci_pipelines")
                    LIMIT 1
                    FOR UPDATE
                    SKIP LOCKED)
            RETURNING ("ci_pipelines"."id")
          SQL
        end
      end

      context 'when running on just the ref' do
        let(:before_pipeline) { nil }

        it 'produces the expected SQL string' do
          expect(subject.squish).to eq <<~SQL.squish
            UPDATE
                "ci_pipelines"
            SET
                "locked" = 0
            WHERE
                "ci_pipelines"."id" IN
                    (SELECT
                        "ci_pipelines"."id"
                    FROM
                        "ci_pipelines"
                    WHERE
                        "ci_pipelines"."ci_ref_id" = #{target_ref.id}
                        AND "ci_pipelines"."locked" = 1
                    LIMIT 1
                    FOR UPDATE
                        SKIP LOCKED)
            RETURNING
                ("ci_pipelines"."id")
          SQL
        end
      end
    end

    describe '#unlock_job_artifacts_query' do
      subject { described_class.new(successful_pipeline.project, successful_pipeline.user).unlock_job_artifacts_query(pipeline_ids) }

      context 'when given a single pipeline ID' do
        let(:pipeline_ids) { [older_pipeline.id] }

        it 'produces the expected SQL string' do
          expect(subject.squish).to eq <<~SQL.squish
            UPDATE
                "ci_job_artifacts"
            SET
                "locked" = 0
            WHERE
                "ci_job_artifacts"."job_id" IN
                    (SELECT
                        "ci_builds"."id"
                    FROM
                        "ci_builds"
                    WHERE
                        "ci_builds"."type" = 'Ci::Build'
                        AND "ci_builds"."commit_id" = #{older_pipeline.id})
            RETURNING
                ("ci_job_artifacts"."id")
          SQL
        end
      end

      context 'when given multiple pipeline IDs' do
        let(:pipeline_ids) { [older_pipeline.id, last_successful_pipeline.id, successful_pipeline.id] }

        it 'produces the expected SQL string' do
          expect(subject.squish).to eq <<~SQL.squish
            UPDATE
                "ci_job_artifacts"
            SET
                "locked" = 0
            WHERE
                "ci_job_artifacts"."job_id" IN
                    (SELECT
                        "ci_builds"."id"
                    FROM
                        "ci_builds"
                    WHERE
                        "ci_builds"."type" = 'Ci::Build'
                        AND "ci_builds"."commit_id" IN (#{pipeline_ids.join(', ')}))
            RETURNING
                ("ci_job_artifacts"."id")
          SQL
        end
      end
    end
  end
end
