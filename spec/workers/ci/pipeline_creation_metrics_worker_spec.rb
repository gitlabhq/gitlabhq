# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineCreationMetricsWorker, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user) }
  let_it_be(:stage) { create(:ci_stage, pipeline: pipeline, project: project) }

  describe '#perform' do
    subject(:perform) { described_class.new.perform(pipeline.id) }

    context 'when pipeline exists' do
      context 'when pipeline has builds' do
        let_it_be(:build1) do
          create(:ci_build, pipeline: pipeline, ci_stage: stage, project: project, name: 'rspec', user: user)
        end

        let_it_be(:build2) do
          create(:ci_build, pipeline: pipeline, ci_stage: stage, project: project, name: 'rubocop', user: user)
        end

        before do
          pipeline.builds.reload
        end

        it 'tracks build creation events' do
          expect { perform }
            .to trigger_internal_events('create_ci_build').twice
        end
      end

      context 'when pipeline has builds with id_tokens' do
        let_it_be(:build_with_tokens) do
          create(:ci_build, pipeline: pipeline, ci_stage: stage, project: project,
            user: user, id_tokens: { 'ID_TOKEN_1' => { aud: 'developers' } })
        end

        before do
          pipeline.builds.reload
        end

        it 'tracks id_tokens usage' do
          expect(::Gitlab::UsageDataCounters::HLLRedisCounter)
            .to receive(:track_event)
            .with('i_ci_secrets_management_id_tokens_build_created', values: [user.id])

          perform
        end

        it 'tracks Snowplow event for id_tokens' do
          perform

          expect_snowplow_event(
            category: 'Ci::Build',
            action: 'create_id_tokens',
            namespace: build_with_tokens.namespace,
            user: user,
            label: 'redis_hll_counters.ci_secrets_management.i_ci_secrets_management_id_tokens_build_created_monthly',
            ultimate_namespace_id: build_with_tokens.namespace.root_ancestor.id,
            context: [Gitlab::Tracking::ServicePingContext.new(
              data_source: :redis_hll,
              event: 'i_ci_secrets_management_id_tokens_build_created'
            ).to_context.to_json]
          )
        end
      end

      context 'when pipeline has no builds' do
        let_it_be(:empty_pipeline) { create(:ci_empty_pipeline, project: project, user: user) }

        it 'does not track any build events' do
          expect(Gitlab::InternalEvents).not_to receive(:track_event).with('create_ci_build', anything)

          described_class.new.perform(empty_pipeline.id)
        end
      end
    end

    context 'when pipeline does not exist' do
      it 'does not track anything' do
        expect(Gitlab::InternalEvents).not_to receive(:track_event)

        described_class.new.perform(non_existing_record_id)
      end
    end

    context 'when tracking pipeline metrics' do
      it 'increments pipeline created counter' do
        counter = instance_double(Prometheus::Client::Counter)
        allow(::Gitlab::Ci::Pipeline::Metrics).to receive(:pipelines_created_counter).and_return(counter)

        expect(counter).to receive(:increment).with(
          source: pipeline.source,
          partition_id: pipeline.partition_id
        )

        perform
      end

      context 'when pipeline has a name', :snowplow do
        it 'tracks snowplow event' do
          issue_url = 'https://gitlab.com/gitlab-org/gitlab/-/issues/424281'
          allow_cross_database_modification_within_transaction(url: issue_url) do
            pipeline.pipeline_metadata = build(:ci_pipeline_metadata, name: 'My Pipeline')
            perform
          end

          expect_snowplow_event(
            category: 'Gitlab::Ci::Pipeline::Chain::Metrics',
            action: 'create_pipeline_with_name',
            project: pipeline.project,
            user: pipeline.user,
            namespace: pipeline.project.namespace
          )
        end
      end

      context 'when pipeline has no name', :snowplow do
        it 'does not track snowplow event' do
          perform

          expect_no_snowplow_event(
            category: 'Gitlab::Ci::Pipeline::Chain::Metrics',
            action: 'create_pipeline_with_name'
          )
        end
      end
    end

    context 'when tracking inputs usage' do
      subject(:perform) { described_class.new.perform(pipeline.id, 3) }

      it 'tracks internal event with count' do
        expect { perform }
          .to trigger_internal_events('create_pipeline_with_inputs')
          .with(
            project: pipeline.project,
            user: pipeline.user
          )
      end

      context 'when inputs_count is nil' do
        subject(:perform) { described_class.new.perform(pipeline.id, nil) }

        it 'does not track event' do
          expect { perform }
            .not_to trigger_internal_events('create_pipeline_with_inputs')
        end
      end

      context 'when inputs_count is zero' do
        subject(:perform) { described_class.new.perform(pipeline.id, 0) }

        it 'does not track event' do
          expect { perform }
            .not_to trigger_internal_events('create_pipeline_with_inputs')
        end
      end
    end

    context 'when tracking template usage' do
      let(:template_names) { ['Auto-DevOps.gitlab-ci.yml', 'Security/SAST.gitlab-ci.yml'] }

      subject(:perform) { described_class.new.perform(pipeline.id, nil, template_names) }

      it 'tracks each template' do
        template_names.each do |template|
          expect(Gitlab::UsageDataCounters::CiTemplateUniqueCounter)
            .to receive(:track_unique_project_event)
            .with(
              project: pipeline.project,
              template: template,
              config_source: pipeline.config_source,
              user: pipeline.user
            )
        end

        perform
      end

      context 'when template_names is nil' do
        subject(:perform) { described_class.new.perform(pipeline.id, nil, nil) }

        it 'does not track anything' do
          expect(Gitlab::UsageDataCounters::CiTemplateUniqueCounter)
            .not_to receive(:track_unique_project_event)

          perform
        end
      end

      context 'when template_names is empty' do
        subject(:perform) { described_class.new.perform(pipeline.id, nil, []) }

        it 'does not track anything' do
          expect(Gitlab::UsageDataCounters::CiTemplateUniqueCounter)
            .not_to receive(:track_unique_project_event)

          perform
        end
      end
    end

    context 'when tracking keyword usage' do
      let(:keyword_usage) { { run: true, only: true, except: false } }

      subject(:perform) { described_class.new.perform(pipeline.id, nil, nil, keyword_usage) }

      it 'tracks only used keywords' do
        expect { perform }
          .to trigger_internal_events('use_run_keyword_in_cicd_yaml')
          .and trigger_internal_events('use_only_keyword_in_cicd_yaml')
          .and not_trigger_internal_events('use_except_keyword_in_cicd_yaml')
      end

      context 'when keyword_usage is nil' do
        subject(:perform) { described_class.new.perform(pipeline.id, nil, nil, nil) }

        it 'does not track anything' do
          expect(Gitlab::InternalEvents).not_to receive(:track_event).with(/use_.*_keyword_in_cicd_yaml/, anything)

          perform
        end
      end

      context 'when keyword_usage is empty' do
        subject(:perform) { described_class.new.perform(pipeline.id, nil, nil, {}) }

        it 'does not track anything' do
          expect(Gitlab::InternalEvents).not_to receive(:track_event).with(/use_.*_keyword_in_cicd_yaml/, anything)

          perform
        end
      end
    end
  end
end
