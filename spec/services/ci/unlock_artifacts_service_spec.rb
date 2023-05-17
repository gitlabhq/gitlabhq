# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::UnlockArtifactsService, feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax

  where(:tag) do
    [
      [false],
      [true]
    ]
  end

  with_them do
    let(:ref) { 'master' }
    let(:ref_path) { tag ? "#{::Gitlab::Git::TAG_REF_PREFIX}#{ref}" : "#{::Gitlab::Git::BRANCH_REF_PREFIX}#{ref}" }
    let(:ci_ref) { create(:ci_ref, ref_path: ref_path) }
    let(:project) { ci_ref.project }
    let(:source_job) { create(:ci_build, pipeline: pipeline) }

    let!(:old_unlocked_pipeline) { create(:ci_pipeline, :with_persisted_artifacts, ref: ref, tag: tag, project: project, locked: :unlocked) }
    let!(:older_pipeline) { create(:ci_pipeline, :with_persisted_artifacts, ref: ref, tag: tag, project: project, locked: :artifacts_locked) }
    let!(:older_ambiguous_pipeline) { create(:ci_pipeline, :with_persisted_artifacts, ref: ref, tag: !tag, project: project, locked: :artifacts_locked) }
    let!(:code_coverage_pipeline) { create(:ci_pipeline, :with_coverage_report_artifact, ref: ref, tag: tag, project: project, locked: :artifacts_locked) }
    let!(:pipeline) { create(:ci_pipeline, :with_persisted_artifacts, ref: ref, tag: tag, project: project, locked: :artifacts_locked) }
    let!(:child_pipeline) { create(:ci_pipeline, :with_persisted_artifacts, ref: ref, tag: tag, child_of: pipeline, project: project, locked: :artifacts_locked) }
    let!(:newer_pipeline) { create(:ci_pipeline, :with_persisted_artifacts, ref: ref, tag: tag, project: project, locked: :artifacts_locked) }
    let!(:other_ref_pipeline) { create(:ci_pipeline, :with_persisted_artifacts, ref: 'other_ref', tag: tag, project: project, locked: :artifacts_locked) }
    let!(:sources_pipeline) { create(:ci_sources_pipeline, source_job: source_job, source_project: project, pipeline: child_pipeline, project: project) }

    before do
      stub_const("#{described_class}::BATCH_SIZE", 1)
    end

    describe '#execute' do
      subject(:execute) { described_class.new(pipeline.project, pipeline.user).execute(ci_ref, before_pipeline) }

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

        it 'unlocks job artifact records' do
          expect { execute }.to change { ::Ci::JobArtifact.artifact_unlocked.count }.from(0).to(2)
        end

        it 'unlocks pipeline artifact records' do
          expect { execute }.to change { ::Ci::PipelineArtifact.artifact_unlocked.count }.from(0).to(1)
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

        it 'unlocks job artifact records' do
          expect { execute }.to change { ::Ci::JobArtifact.artifact_unlocked.count }.from(0).to(8)
        end

        it 'unlocks pipeline artifact records' do
          expect { execute }.to change { ::Ci::PipelineArtifact.artifact_unlocked.count }.from(0).to(1)
        end
      end
    end

    describe '#unlock_pipelines_query' do
      subject { described_class.new(pipeline.project, pipeline.user).unlock_pipelines_query(ci_ref, before_pipeline) }

      context 'when running on a ref before a pipeline' do
        let(:before_pipeline) { pipeline }

        it 'produces the expected SQL string' do
          # To be removed when the ignored column id_convert_to_bigint for ci_pipelines is removed
          # see https://gitlab.com/gitlab-org/gitlab/-/issues/397000
          selected_columns =
            Ci::Pipeline.column_names.map do |field|
              Ci::Pipeline.connection.quote_table_name("#{Ci::Pipeline.table_name}.#{field}")
            end.join(', ')
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
                        "ci_pipelines"."ci_ref_id" = #{ci_ref.id}
                        AND "ci_pipelines"."locked" = 1
                        AND "ci_pipelines"."id" < #{before_pipeline.id}
                        AND "ci_pipelines"."id" NOT IN
                            (WITH RECURSIVE
                                "base_and_descendants"
                            AS
                                ((SELECT
                                    #{selected_columns}
                                FROM
                                    "ci_pipelines"
                                WHERE
                                    "ci_pipelines"."id" = #{before_pipeline.id})
                            UNION
                                (SELECT
                                    #{selected_columns}
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
                        "ci_pipelines"."ci_ref_id" = #{ci_ref.id}
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
      subject { described_class.new(pipeline.project, pipeline.user).unlock_job_artifacts_query(pipeline_ids) }

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
        let(:pipeline_ids) { [older_pipeline.id, newer_pipeline.id, pipeline.id] }

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
