# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService, :clean_gitlab_redis_cache, feature_category: :continuous_integration do
  include ProjectForksHelper
  include Ci::PipelineMessageHelpers

  let_it_be_with_refind(:project) { create(:project, :repository) }
  let_it_be_with_reload(:user) { project.first_owner }

  let(:ref_name) { 'refs/heads/master' }

  before do
    project.update!(ci_pipeline_variables_minimum_override_role: :maintainer)
    stub_ci_pipeline_to_return_yaml_file
  end

  describe '#execute' do
    # rubocop:disable Metrics/ParameterLists
    def execute_service(
      source: :push,
      before: '00000000',
      after: project.commit.id,
      ref: ref_name,
      trigger_request: nil,
      variables_attributes: nil,
      merge_request: nil,
      external_pull_request: nil,
      push_options: nil,
      source_sha: nil,
      target_sha: nil,
      partition_id: nil,
      save_on_errors: true,
      pipeline_creation_request: nil)
      params = { ref: ref,
                 before: before,
                 after: after,
                 variables_attributes: variables_attributes,
                 push_options: push_options,
                 source_sha: source_sha,
                 target_sha: target_sha,
                 partition_id: partition_id,
                 pipeline_creation_request: pipeline_creation_request }

      described_class.new(project, user, params).execute(source,
        save_on_errors: save_on_errors,
        trigger_request: trigger_request,
        merge_request: merge_request,
        external_pull_request: external_pull_request) do |pipeline|
        yield(pipeline) if block_given?
      end
    end
    # rubocop:enable Metrics/ParameterLists

    context 'performance' do
      it_behaves_like 'pipelines are created without N+1 SQL queries' do
        let(:config1) do
          <<~YAML
            job1:
              stage: build
              script: exit 0

            job2:
              stage: test
              script: exit 0
          YAML
        end

        let(:config2) do
          <<~YAML
            job1:
              stage: build
              script: exit 0

            job2:
              stage: test
              script: exit 0

            job3:
              stage: deploy
              script: exit 0
          YAML
        end

        let(:accepted_n_plus_ones) do
          1 + # SELECT "ci_instance_variables"
            1 + # INSERT INTO "ci_stages"
            1 + # SELECT "ci_builds".* FROM "ci_builds"
            1 + # INSERT INTO "ci_builds"
            1 + # INSERT INTO "ci_builds_metadata"
            1   # SELECT "taggings".* FROM "taggings"
        end
      end
    end

    context 'valid params' do
      let(:pipeline) { execute_service.payload }

      let(:pipeline_on_previous_commit) do
        execute_service(
          after: previous_commit_sha_from_ref('master')
        ).payload
      end

      it 'responds with success' do
        expect(execute_service).to be_success
      end

      it 'creates a pipeline' do
        expect(pipeline).to be_kind_of(Ci::Pipeline)
        expect(pipeline).to be_valid
        expect(pipeline).to be_persisted
        expect(pipeline).to be_push
        expect(pipeline).to eq(project.ci_pipelines.last)
        expect(pipeline).to have_attributes(user: user)
        expect(pipeline).to have_attributes(status: 'created')
        expect(pipeline.iid).not_to be_nil
        expect(pipeline.repository_source?).to be true
        expect(pipeline.builds.first).to be_kind_of(Ci::Build)
        expect(pipeline.yaml_errors).not_to be_present
      end

      it 'increments the prometheus counter' do
        counter = spy('pipeline created counter')

        allow(Gitlab::Ci::Pipeline::Metrics)
          .to receive(:pipelines_created_counter).and_return(counter)

        pipeline

        expect(counter).to have_received(:increment)
      end

      it 'records pipeline size in a prometheus histogram' do
        histogram = spy('pipeline size histogram')

        allow(Gitlab::Ci::Pipeline::Metrics)
          .to receive(:pipeline_size_histogram).and_return(histogram)

        execute_service

        expect(histogram).to have_received(:observe)
          .with({ source: 'push', plan: project.actual_plan_name }, 5)
      end

      it 'tracks included template usage' do
        expect_next_instance_of(Gitlab::Ci::Pipeline::Chain::TemplateUsage) do |instance|
          expect(instance).to receive(:perform!)
        end

        execute_service
      end

      it 'tracks included catalog component usage' do
        expect_next_instance_of(Gitlab::Ci::Pipeline::Chain::ComponentUsage) do |instance|
          expect(instance).to receive(:perform!)
        end

        execute_service
      end

      it 'creates pipeline_config' do
        expect { execute_service }
          .to change { Ci::PipelineConfig.count }.by(1)
      end

      context 'when merge requests already exist for this source branch' do
        let!(:merge_request_1) do
          create(:merge_request, source_branch: 'feature', target_branch: "master", source_project: project)
        end

        let!(:merge_request_2) do
          create(:merge_request, source_branch: 'feature', target_branch: "v1.1.0", source_project: project)
        end

        context 'when the head pipeline sha equals merge request sha' do
          it 'updates head pipeline of each merge request', :sidekiq_might_not_need_inline do
            head_pipeline = execute_service(ref: 'feature', after: nil).payload

            expect(merge_request_1.reload.head_pipeline).to eq(head_pipeline)
            expect(merge_request_2.reload.head_pipeline).to eq(head_pipeline)
          end
        end
      end

      context 'auto-cancel enabled' do
        before do
          project.update!(auto_cancel_pending_pipelines: 'enabled')
        end

        it 'does not cancel HEAD pipeline' do
          pipeline
          pipeline_on_previous_commit

          expect(pipeline.reload).to have_attributes(status: 'created', auto_canceled_by_id: nil)
        end

        it 'auto cancel pending non-HEAD pipelines', :sidekiq_might_not_need_inline do
          pipeline_on_previous_commit
          pipeline

          expect(pipeline_on_previous_commit.reload).to have_attributes(status: 'canceled', auto_canceled_by_id: pipeline.id)
        end

        it 'cancels running outdated pipelines', :sidekiq_inline do
          pipeline_on_previous_commit.reload.run
          head_pipeline = execute_service.payload

          expect(pipeline_on_previous_commit.reload).to have_attributes(status: 'canceled', auto_canceled_by_id: head_pipeline.id)
        end

        it 'cancel created outdated pipelines', :sidekiq_might_not_need_inline do
          pipeline_on_previous_commit.update!(status: 'created')
          pipeline

          expect(pipeline_on_previous_commit.reload).to have_attributes(status: 'canceled', auto_canceled_by_id: pipeline.id)
        end

        it 'does not cancel pipelines from the other branches' do
          new_pipeline = execute_service(
            ref: 'refs/heads/feature',
            after: previous_commit_sha_from_ref('feature')
          ).payload

          pipeline

          expect(new_pipeline.reload).to have_attributes(status: 'created', auto_canceled_by_id: nil)
        end

        context 'when the interruptible attribute is' do
          context 'not defined' do
            before do
              config = YAML.dump(rspec: { script: 'echo' })
              stub_ci_pipeline_yaml_file(config)
            end

            it 'is cancelable' do
              pipeline = execute_service.payload

              expect(pipeline.builds.find_by(name: 'rspec').interruptible).to be_nil
            end
          end

          context 'set to true' do
            before do
              config = YAML.dump(rspec: { script: 'echo', interruptible: true })
              stub_ci_pipeline_yaml_file(config)
            end

            it 'is cancelable' do
              pipeline = execute_service.payload

              expect(pipeline.builds.find_by(name: 'rspec').interruptible).to be_truthy
            end
          end

          context 'set to false' do
            before do
              config = YAML.dump(rspec: { script: 'echo', interruptible: false })
              stub_ci_pipeline_yaml_file(config)
            end

            it 'is not cancelable' do
              pipeline = execute_service.payload

              expect(pipeline.builds.find_by(name: 'rspec').interruptible).to be_falsy
            end
          end
        end

        context 'interruptible builds' do
          before do
            stub_ci_pipeline_yaml_file(YAML.dump(config))
          end

          let(:config) do
            {
              stages: %w[stage1 stage2 stage3 stage4],

              build_1_1: {
                stage: 'stage1',
                script: 'echo',
                interruptible: true
              },
              build_1_2: {
                stage: 'stage1',
                script: 'echo',
                interruptible: true
              },
              build_2_1: {
                stage: 'stage2',
                script: 'echo',
                when: 'delayed',
                start_in: '10 minutes',
                interruptible: true
              },
              build_3_1: {
                stage: 'stage3',
                script: 'echo',
                interruptible: false
              },
              build_4_1: {
                stage: 'stage4',
                script: 'echo'
              }
            }
          end

          it 'properly configures interruptible status' do
            interruptible_status =
              pipeline_on_previous_commit
                .builds
                .joins(:metadata)
                .pluck(:name, "#{Ci::BuildMetadata.quoted_table_name}.interruptible")

            expect(interruptible_status).to contain_exactly(
              ['build_1_1', true],
              ['build_1_2', true],
              ['build_2_1', true],
              ['build_3_1', false],
              ['build_4_1', nil]
            )
          end

          context 'when only interruptible builds are running' do
            context 'when build marked explicitly by interruptible is running' do
              it 'cancels running outdated pipelines', :sidekiq_inline do
                pipeline_on_previous_commit
                  .builds
                  .find_by_name('build_1_2')
                  .run!

                pipeline

                expect(pipeline_on_previous_commit.reload).to have_attributes(
                  status: 'canceled', auto_canceled_by_id: pipeline.id)
              end
            end

            context 'when build that is not marked as interruptible is running' do
              it 'cancels running outdated pipelines', :sidekiq_inline do
                build_2_1 = pipeline_on_previous_commit
                  .builds.find_by_name('build_2_1')

                build_2_1.enqueue!
                build_2_1.reset.run!

                pipeline

                expect(pipeline_on_previous_commit.reload).to have_attributes(
                  status: 'canceled', auto_canceled_by_id: pipeline.id)
              end
            end
          end

          context 'when an uninterruptible build is running' do
            it 'does not cancel running outdated pipelines', :sidekiq_inline do
              build_3_1 = pipeline_on_previous_commit
                .builds.find_by_name('build_3_1')

              build_3_1.enqueue!
              build_3_1.reset.run!

              pipeline

              expect(pipeline_on_previous_commit.reload).to have_attributes(
                status: 'running', auto_canceled_by_id: nil)
            end
          end

          context 'when an build is waiting on an interruptible scheduled task' do
            it 'cancels running outdated pipelines', :sidekiq_might_not_need_inline do
              allow(Ci::BuildScheduleWorker).to receive(:perform_at)

              pipeline_on_previous_commit
                .builds
                .find_by_name('build_2_1')
                .schedule!

              pipeline

              expect(pipeline_on_previous_commit.reload).to have_attributes(
                status: 'canceled', auto_canceled_by_id: pipeline.id)
            end
          end

          context 'when a uninterruptible build has finished' do
            it 'does not cancel running outdated pipelines', :sidekiq_might_not_need_inline do
              pipeline_on_previous_commit
                .builds
                .find_by_name('build_3_1')
                .success!

              pipeline

              expect(pipeline_on_previous_commit.reload).to have_attributes(
                status: 'running', auto_canceled_by_id: nil)
            end
          end
        end
      end

      context 'auto-cancel disabled' do
        before do
          project.update!(auto_cancel_pending_pipelines: 'disabled')
        end

        it 'does not auto cancel created non-HEAD pipelines' do
          pipeline_on_previous_commit
          pipeline

          expect(pipeline_on_previous_commit.reload)
            .to have_attributes(status: 'created', auto_canceled_by_id: nil)
        end
      end

      def previous_commit_sha_from_ref(ref)
        project.commit(ref).parent.sha
      end
    end

    context "skip tag if there is no build for it" do
      it "creates commit if there is appropriate job" do
        expect(execute_service.payload).to be_persisted
      end

      it "creates commit if there is no appropriate job but deploy job has right ref setting" do
        config = YAML.dump({ deploy: { script: "ls", only: ["master"] } })
        stub_ci_pipeline_yaml_file(config)

        expect(execute_service.payload).to be_persisted
      end
    end

    it 'skips creating pipeline for refs without .gitlab-ci.yml', :aggregate_failures do
      stub_ci_pipeline_yaml_file(nil)

      response = execute_service

      expect(response).to be_error
      expect(response.message).to eq('Missing CI config file')
      expect(response.payload).not_to be_persisted
      expect(Ci::Pipeline.count).to eq(0)
    end

    shared_examples 'a failed pipeline' do
      it 'creates failed pipeline' do
        stub_ci_pipeline_yaml_file(ci_yaml)

        pipeline = execute_service.payload

        expect(pipeline).to be_persisted
        expect(pipeline.builds.any?).to be false
        expect(pipeline.status).to eq('failed')
        expect(pipeline.yaml_errors).not_to be_nil
      end
    end

    context 'config evaluation' do
      context 'when config is in a file in repository' do
        before do
          content = YAML.dump(rspec: { script: 'echo' })
          stub_ci_pipeline_yaml_file(content)
        end

        it 'pull it from the repository' do
          pipeline = execute_service.payload
          expect(pipeline).to be_repository_source
          expect(pipeline.builds.map(&:name)).to eq ['rspec']
        end
      end

      context 'when config is from Auto-DevOps' do
        before do
          stub_ci_pipeline_yaml_file(nil)
          allow_any_instance_of(Project).to receive(:auto_devops_enabled?).and_return(true)
          create(:project_auto_devops, project: project)
        end

        it 'pull it from Auto-DevOps' do
          pipeline = execute_service.payload
          expect(pipeline).to be_auto_devops_source
          expect(pipeline.builds.map(&:name)).to match_array(%w[build code_quality container_scanning secret_detection semgrep-sast test])
        end
      end

      context 'when config is not found' do
        before do
          stub_ci_pipeline_yaml_file(nil)
        end

        it 'responds with error message', :aggregate_failures do
          response = execute_service

          expect(response).to be_error
          expect(response.message).to eq('Missing CI config file')
          expect(response.payload).not_to be_persisted
        end
      end

      context 'when an unexpected error is raised' do
        before do
          expect(Gitlab::Ci::YamlProcessor).to receive(:new)
            .and_raise(RuntimeError, 'undefined failure')
        end

        it 'saves error in pipeline' do
          pipeline = execute_service.payload

          expect(pipeline.yaml_errors).to include('Undefined error')
        end

        it 'logs error' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception).and_call_original

          execute_service
        end
      end
    end

    context 'when yaml is invalid' do
      let(:ci_yaml) { 'invalid: file: fiile' }
      let(:message) { 'Message' }

      it_behaves_like 'a failed pipeline'

      it 'increments the error metric' do
        stub_ci_pipeline_yaml_file(ci_yaml)

        counter = Gitlab::Metrics.counter(:gitlab_ci_pipeline_failure_reasons, 'desc')
        expect { execute_service }.to change { counter.get(reason: 'config_error') }.by(1)
      end

      context 'when receive git commit' do
        before do
          allow_any_instance_of(Ci::Pipeline).to receive(:git_commit_message) { message }
        end

        it_behaves_like 'a failed pipeline'
      end

      context 'when config has ports' do
        context 'in the main image' do
          let(:ci_yaml) do
            <<-EOS
              image:
                name: image:1.0
                ports:
                  - 80
            EOS
          end

          it_behaves_like 'a failed pipeline'
        end

        context 'in the job image' do
          let(:ci_yaml) do
            <<-EOS
              image: image:1.0

              test:
                script: rspec
                image:
                  name: image:1.0
                  ports:
                    - 80
            EOS
          end

          it_behaves_like 'a failed pipeline'
        end

        context 'in the service' do
          let(:ci_yaml) do
            <<-EOS
              image: image:1.0

              test:
                script: rspec
                image: image:1.0
                services:
                  - name: test
                    ports:
                      - 80
            EOS
          end

          it_behaves_like 'a failed pipeline'
        end
      end
    end

    context 'when an unexpected error is raised' do
      before do
        expect(Gitlab::Ci::YamlProcessor).to receive(:new)
          .and_raise(RuntimeError, 'undefined failure')
      end

      it 'saves error in pipeline' do
        pipeline = execute_service.payload

        expect(pipeline.yaml_errors).to include('Undefined error')
      end

      it 'logs error' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).and_call_original

        execute_service
      end
    end

    context 'when commit contains a [ci skip] directive' do
      shared_examples 'creating a pipeline' do
        it 'does not skip pipeline creation' do
          pipeline = execute_service.payload

          expect(pipeline).to be_persisted
          expect(pipeline.builds.first.name).to eq("rspec")
        end
      end

      shared_examples 'skipping a pipeline' do
        it 'skips pipeline creation' do
          pipeline = execute_service.payload

          expect(pipeline).to be_persisted
          expect(pipeline.builds.any?).to be false
          expect(pipeline.status).to eq("skipped")
        end
      end

      before do
        allow_any_instance_of(Ci::Pipeline).to receive(:git_commit_message) { commit_message }
      end

      skip_commit_messages = [
        "some message[ci skip]",
        "some message[skip ci]",
        "some message[CI SKIP]",
        "some message[SKIP CI]",
        "some message[ci_skip]",
        "some message[skip_ci]",
        "some message[ci-skip]",
        "some message[skip-ci]"
      ]

      skip_commit_messages.each do |skip_commit_message|
        context "when the commit message is #{skip_commit_message}" do
          let(:commit_message) { skip_commit_message }

          it_behaves_like 'skipping a pipeline'
        end
      end

      context 'when commit message does not contain [ci skip] nor [skip ci]' do
        let(:commit_message) { 'some message' }

        it_behaves_like 'creating a pipeline'
      end

      context 'when commit message is nil' do
        let(:commit_message) { nil }

        it_behaves_like 'creating a pipeline'
      end

      context 'when there is [ci skip] tag in commit message and yaml is invalid' do
        let(:commit_message) { 'some message [ci skip]' }
        let(:ci_yaml) { 'invalid: file: fiile' }

        before do
          stub_ci_pipeline_yaml_file(ci_yaml)
        end

        it_behaves_like 'skipping a pipeline'
      end
    end

    context 'when push options contain ci.skip' do
      let(:push_options) do
        { 'ci' => { 'skip' => true } }
      end

      it 'creates a pipline in the skipped state' do
        pipeline = execute_service(push_options: push_options).payload

        # TODO: DRY these up with "skips builds creation if the commit message"
        expect(pipeline).to be_persisted
        expect(pipeline.builds.any?).to be false
        expect(pipeline.status).to eq("skipped")
      end
    end

    context 'when there are no jobs for this pipeline' do
      before do
        config = YAML.dump({ test: { script: 'ls', only: ['feature'] } })
        stub_ci_pipeline_yaml_file(config)
      end

      it 'does not create a new pipeline', :aggregate_failures do
        result = execute_service

        expect(result).to be_error
        expect(result.message).to eq(sanitize_message(Ci::Pipeline.rules_failure_message))
        expect(result.payload).not_to be_persisted
        expect(Ci::Build.all).to be_empty
        expect(Ci::Pipeline.count).to eq(0)
      end

      describe '#iid' do
        let(:internal_id) do
          InternalId.find_by(project_id: project.id, usage: :ci_pipelines)
        end

        before do
          expect_any_instance_of(Ci::Pipeline).to receive(:ensure_project_iid!)
            .and_call_original
        end

        it 'rewinds iid', :aggregate_failures do
          result = execute_service

          expect(result).to be_error
          expect(result.payload).not_to be_persisted
          expect(internal_id.last_value).to eq(0)
        end
      end
    end

    context 'when the configuration includes ID tokens' do
      it 'creates variables for the ID tokens' do
        config = YAML.dump({
          job_with_id_tokens: {
            script: 'ls',
            id_tokens: {
              'TEST_ID_TOKEN' => {
                aud: 'https://gitlab.com'
              }
            }
          }
        })
        stub_ci_pipeline_yaml_file(config)

        result = execute_service.payload

        expect(result).to be_persisted
        expect(result.builds.first.id_tokens).to eq({
          'TEST_ID_TOKEN' => { 'aud' => 'https://gitlab.com' }
        })
      end
    end

    context 'with manual actions' do
      before do
        config = YAML.dump({ deploy: { script: 'ls', when: 'manual' } })
        stub_ci_pipeline_yaml_file(config)
      end

      it 'does not create a new pipeline', :sidekiq_inline do
        result = execute_service.payload

        expect(result).to be_persisted
        expect(result.manual_actions).not_to be_empty
      end
    end

    context 'when builds with auto-retries are configured' do
      let(:pipeline)  { execute_service.payload }
      let(:rspec_job) { pipeline.builds.find_by(name: 'rspec') }

      before do
        stub_ci_pipeline_yaml_file(YAML.dump({
          rspec: { script: 'rspec', retry: retry_value }
        }))
        rspec_job.update!(options: { retry: retry_value })
      end

      context 'as an integer' do
        let(:retry_value) { 2 }

        it 'correctly creates builds with auto-retry value configured' do
          expect(pipeline).to be_persisted
        end
      end

      context 'as hash' do
        let(:retry_value) { { max: 2, when: 'runner_system_failure' } }

        it 'correctly creates builds with auto-retry value configured' do
          expect(pipeline).to be_persisted
        end
      end
    end

    context 'with resource group' do
      context 'when resource group is defined' do
        before do
          config = YAML.dump(
            test: { stage: 'test', script: 'ls', resource_group: resource_group_key }
          )

          stub_ci_pipeline_yaml_file(config)
        end

        let(:resource_group_key) { 'iOS' }

        it 'persists the association correctly' do
          result = execute_service.payload
          deploy_job = result.builds.find_by_name!(:test)
          resource_group = project.resource_groups.find_by_key!(resource_group_key)

          expect(result).to be_persisted
          expect(deploy_job.resource_group.key).to eq(resource_group_key)
          expect(project.resource_groups.count).to eq(1)
          expect(resource_group.processables.count).to eq(1)
          expect(resource_group.resources.count).to eq(1)
          expect(resource_group.resources.first.processable).to eq(nil)
        end

        context 'when resource group key includes predefined variables' do
          let(:resource_group_key) { '$CI_COMMIT_REF_NAME-$CI_JOB_NAME' }

          it 'interpolates the variables into the key correctly' do
            result = execute_service.payload

            expect(result).to be_persisted
            expect(project.resource_groups.exists?(key: 'master-test')).to eq(true)
          end
        end
      end
    end

    context 'when resource group is defined for review app deployment' do
      before do
        config = YAML.dump(
          review_app: {
            stage: 'test',
            script: 'deploy',
            environment: {
              name: 'review/$CI_COMMIT_REF_SLUG',
              on_stop: 'stop_review_app'
            },
            resource_group: '$CI_ENVIRONMENT_NAME'
          },
          stop_review_app: {
            stage: 'test',
            script: 'stop',
            when: 'manual',
            environment: {
              name: 'review/$CI_COMMIT_REF_SLUG',
              action: 'stop'
            },
            resource_group: '$CI_ENVIRONMENT_NAME'
          }
        )

        stub_ci_pipeline_yaml_file(config)
      end

      it 'persists the association correctly' do
        result = execute_service.payload
        deploy_job = result.builds.find_by_name!(:review_app)
        stop_job = result.builds.find_by_name!(:stop_review_app)

        expect(result).to be_persisted
        expect(deploy_job.resource_group.key).to eq('review/master')
        expect(stop_job.resource_group.key).to eq('review/master')
        expect(project.resource_groups.count).to eq(1)
      end

      it 'initializes scoped variables only once for each build' do
        # Bypassing `stub_build` hack because it distrubs the expectations below.
        allow_next_instances_of(Gitlab::Ci::Build::Context::Build, 2) do |build_context|
          allow(build_context).to receive(:variables) { Gitlab::Ci::Variables::Collection.new }
        end

        expect_next_instances_of(::Ci::Build, 2) do |ci_build|
          expect(ci_build).to receive(:scoped_variables).once.and_call_original
        end

        expect(execute_service.payload).to be_created_successfully
      end
    end

    context 'with timeout' do
      context 'when builds with custom timeouts are configured' do
        before do
          config = YAML.dump(rspec: { script: 'rspec', timeout: '2m 3s' })
          stub_ci_pipeline_yaml_file(config)
        end

        it 'correctly creates builds with custom timeout value configured' do
          pipeline = execute_service.payload

          expect(pipeline).to be_persisted
          expect(pipeline.builds.find_by(name: 'rspec').options[:job_timeout]).to eq 123
        end
      end
    end

    context 'with release' do
      shared_examples_for 'a successful release pipeline' do
        before do
          stub_ci_pipeline_yaml_file(YAML.dump(config))
        end

        it 'is valid config' do
          pipeline = execute_service.payload
          build = pipeline.builds.first
          expect(pipeline).to be_kind_of(Ci::Pipeline)
          expect(pipeline).to be_valid
          expect(pipeline.yaml_errors).not_to be_present
          expect(pipeline).to be_persisted
          expect(build).to be_kind_of(Ci::Build)
          expect(build.options).to eq(config[:release].except(:stage, :only))
          expect(build).to be_persisted
        end
      end

      context 'simple example' do
        it_behaves_like 'a successful release pipeline' do
          let(:config) do
            {
              release: {
                script: ["make changelog | tee release_changelog.txt"],
                release: {
                  tag_name: "v0.06",
                  description: "./release_changelog.txt"
                }
              }
            }
          end
        end
      end

      context 'example with all release metadata' do
        it_behaves_like 'a successful release pipeline' do
          let(:config) do
            {
              release: {
                script: ["make changelog | tee release_changelog.txt"],
                release: {
                  name: "Release $CI_TAG_NAME",
                  tag_name: "v0.06",
                  description: "./release_changelog.txt",
                  assets: {
                    links: [
                      {
                        name: "cool-app.zip",
                        url: "http://my.awesome.download.site/1.0-$CI_COMMIT_SHORT_SHA.zip"
                      },
                      {
                        url: "http://my.awesome.download.site/1.0-$CI_COMMIT_SHORT_SHA.exe"
                      }
                    ]
                  }
                }
              }
            }
          end
        end
      end
    end

    shared_examples 'when ref is protected' do
      let(:user) { create(:user) }

      context 'when user is developer' do
        before do
          project.add_developer(user)
        end

        it 'does not create a pipeline', :aggregate_failures do
          expect(execute_service.payload).not_to be_persisted
          expect(Ci::Pipeline.count).to eq(0)
        end
      end

      context 'when user is maintainer' do
        let(:pipeline) { execute_service.payload }

        before do
          project.add_maintainer(user)
        end

        it 'creates a protected pipeline' do
          expect(pipeline).to be_persisted
          expect(pipeline).to be_protected
          expect(Ci::Pipeline.count).to eq(1)
        end
      end

      context 'when trigger belongs to no one' do
        let(:user) {}
        let(:trigger_request) { create(:ci_trigger_request, project_id: project.id) }

        it 'does not create a pipeline', :aggregate_failures do
          response = execute_service(trigger_request: trigger_request)

          expect(response).to be_error
          expect(response.payload).not_to be_persisted
          expect(Ci::Pipeline.count).to eq(0)
        end
      end

      context 'when trigger belongs to a developer' do
        let(:user) { create(:user) }
        let(:trigger) { create(:ci_trigger, owner: user, project: project) }
        let(:trigger_request) { create(:ci_trigger_request, trigger: trigger) }

        before do
          project.add_developer(user)
        end

        it 'does not create a pipeline', :aggregate_failures do
          response = execute_service(trigger_request: trigger_request)

          expect(response).to be_error
          expect(response.payload).not_to be_persisted
          expect(Ci::Pipeline.count).to eq(0)
        end
      end

      context 'when trigger belongs to a maintainer' do
        let(:user) { create(:user) }
        let(:trigger) { create(:ci_trigger, owner: user, project: project) }
        let(:trigger_request) { create(:ci_trigger_request, trigger: trigger) }

        before do
          project.add_maintainer(user)
        end

        it 'creates a pipeline' do
          expect(execute_service(trigger_request: trigger_request).payload)
            .to be_persisted
          expect(Ci::Pipeline.count).to eq(1)
        end
      end
    end

    context 'when ref is a protected branch' do
      before do
        create(:protected_branch, project: project, name: 'master')
      end

      it_behaves_like 'when ref is protected'
    end

    context 'when ref is a protected tag' do
      let(:ref_name) { 'refs/tags/v1.0.0' }

      before do
        create(:protected_tag, project: project, name: '*')
      end

      it_behaves_like 'when ref is protected'
    end

    context 'when pipeline is running for a tag' do
      before do
        config = YAML.dump(
          test: { script: 'test', only: ['branches'] },
          deploy: { script: 'deploy', only: ['tags'] }
        )

        stub_ci_pipeline_yaml_file(config)
      end

      it 'creates a tagged pipeline' do
        pipeline = execute_service(ref: 'v1.0.0').payload

        expect(pipeline.tag?).to be true
      end
    end

    context 'when pipeline is running for a nonexistant-branch' do
      let(:gitlab_ci_yaml) { YAML.dump(test: { script: 'test' }) }

      let(:ref_name) { 'refs/heads/nonexistant-branch' }

      let(:pipeline) { execute_service.payload }

      it 'does not create the pipeline' do
        expect(pipeline).not_to be_created_successfully
        expect(pipeline.errors[:base]).to eq(['Reference not found'])
      end

      context 'when there is a tag with that nonexistant-branch' do
        # v1.0.0 is on the test repo as a tag
        let(:ref_name) { 'refs/heads/v1.0.0' }

        it 'does not create the pipeline' do
          expect(pipeline).not_to be_created_successfully
          expect(pipeline.errors[:base]).to eq(['Reference not found'])
        end
      end
    end

    context 'when pipeline is running for a branch with the name of both a branch and a tag' do
      let(:gitlab_ci_yaml) { YAML.dump(test: { script: 'test' }) }

      # v1.1.0 is on the test repo as branch and tag
      let(:ref_name) { 'refs/heads/v1.1.0' }

      let(:pipeline) { execute_service.payload }

      it 'creates the pipeline for the branch' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.branch?).to be true
        expect(pipeline.tag?).to be false
      end
    end

    context 'when pipeline is running for a tag with the name of both a branch and a tag' do
      let(:gitlab_ci_yaml) { YAML.dump(test: { script: 'test' }) }

      # v1.1.0 is on the test repo as branch and tag
      let(:ref_name) { 'refs/tags/v1.1.0' }

      let(:pipeline) { execute_service.payload }

      it 'creates the pipeline for the tag' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.branch?).to be false
        expect(pipeline.tag?).to be true
      end
    end

    context 'when pipeline is running for an ambiguous ref' do
      let(:gitlab_ci_yaml) { YAML.dump(test: { script: 'test' }) }

      # v1.1.0 is on the test repo as branch and tag
      let(:ref_name) { 'v1.1.0' }

      let(:pipeline) { execute_service.payload }

      it 'does not create the pipeline' do
        expect(pipeline).not_to be_created_successfully
        expect(pipeline.errors[:base]).to eq(['Ref is ambiguous'])
      end
    end

    context 'when pipeline variables are specified' do
      subject(:pipeline) { execute_service(variables_attributes: variables_attributes).payload }

      context 'with valid pipeline variables' do
        let(:variables_attributes) do
          [{ key: 'first', secret_value: 'world' },
            { key: 'second', secret_value: 'second_world' }]
        end

        it 'creates a pipeline with specified variables' do
          expect(pipeline.variables.map { |var| var.slice(:key, :secret_value) })
            .to eq variables_attributes.map(&:with_indifferent_access)
        end
      end

      context 'with duplicate pipeline variables' do
        let(:variables_attributes) do
          [{ key: 'hello', secret_value: 'world' },
            { key: 'hello', secret_value: 'second_world' }]
        end

        it 'fails to create the pipeline' do
          expect(pipeline).to be_failed
          expect(pipeline.variables).to be_empty
          expect(pipeline.errors[:base]).to eq(['Duplicate variable name: hello'])
        end
      end

      context 'with more than one duplicate pipeline variable' do
        let(:variables_attributes) do
          [{ key: 'hello', secret_value: 'world' },
            { key: 'hello', secret_value: 'second_world' },
            { key: 'single', secret_value: 'variable' },
            { key: 'other', secret_value: 'value' },
            { key: 'other', secret_value: 'other value' }]
        end

        it 'fails to create the pipeline' do
          expect(pipeline).to be_failed
          expect(pipeline.variables).to be_empty
          expect(pipeline.errors[:base]).to eq(['Duplicate variable names: hello, other'])
        end
      end
    end

    describe 'Pipeline for external pull requests' do
      let(:response) do
        execute_service(
          source: source,
          external_pull_request: pull_request,
          ref: ref_name,
          source_sha: source_sha,
          target_sha: target_sha
        )
      end

      let(:pipeline) { response.payload }

      before do
        stub_ci_pipeline_yaml_file(YAML.dump(config))
      end

      let(:ref_name) { 'refs/heads/feature' }
      let(:source_sha) { project.commit(ref_name).id }
      let(:target_sha) { nil }

      context 'when source is external pull request' do
        let(:source) { :external_pull_request_event }

        context 'when config has external_pull_requests keywords' do
          let(:config) do
            {
              build: {
                stage: 'build',
                script: 'echo'
              },
              test: {
                stage: 'test',
                script: 'echo',
                only: ['external_pull_requests']
              },
              pages: {
                stage: 'deploy',
                script: 'echo',
                except: ['external_pull_requests']
              }
            }
          end

          context 'when external pull request is specified' do
            let(:pull_request) { create(:external_pull_request, project: project, source_branch: 'feature', target_branch: 'master') }
            let(:ref_name) { pull_request.source_ref }

            it 'creates an external pull request pipeline' do
              expect(pipeline).to be_persisted
              expect(pipeline).to be_external_pull_request_event
              expect(pipeline.external_pull_request).to eq(pull_request)
              expect(pipeline.source_sha).to eq(source_sha)
              expect(pipeline.builds.order(:stage_id)
                .map(&:name))
                .to eq(%w[build test])
            end

            context 'when ref is tag' do
              let(:ref_name) { 'refs/tags/v1.1.0' }

              it 'does not create an extrnal pull request pipeline', :aggregate_failures do
                expect(response).to be_error
                expect(response.message).to eq('Tag is not included in the list and Failed to build the pipeline!')
                expect(pipeline).not_to be_persisted
                expect(pipeline.errors[:tag]).to eq(['is not included in the list'])
              end
            end

            context 'when pull request is created from fork' do
              it 'does not create an external pull request pipeline'
            end

            context "when there are no matched jobs" do
              let(:config) do
                {
                  test: {
                    stage: 'test',
                    script: 'echo',
                    except: ['external_pull_requests']
                  }
                }
              end

              it 'does not create a detached merge request pipeline', :aggregate_failures do
                expect(response).to be_error
                expect(response.message).to eq(sanitize_message(Ci::Pipeline.rules_failure_message))
                expect(pipeline).not_to be_persisted
                expect(pipeline.errors[:base]).to eq([sanitize_message(Ci::Pipeline.rules_failure_message)])
              end
            end
          end

          context 'when external pull request is not specified' do
            let(:pull_request) { nil }

            it 'does not create an external pull request pipeline', :aggregate_failures do
              expect(response).to be_error
              expect(response.message).to eq("External pull request can't be blank and Failed to build the pipeline!")
              expect(pipeline).not_to be_persisted
              expect(pipeline.errors[:external_pull_request]).to eq(["can't be blank"])
            end
          end
        end

        context "when config does not have external_pull_requests keywords" do
          let(:config) do
            {
              build: {
                stage: 'build',
                script: 'echo'
              },
              test: {
                stage: 'test',
                script: 'echo'
              },
              pages: {
                stage: 'deploy',
                script: 'echo'
              }
            }
          end

          context 'when external pull request is specified' do
            let(:pull_request) do
              create(:external_pull_request,
                project: project,
                source_branch: Gitlab::Git.ref_name(ref_name),
                target_branch: 'master')
            end

            it 'creates an external pull request pipeline' do
              expect(pipeline).to be_persisted
              expect(pipeline).to be_external_pull_request_event
              expect(pipeline.external_pull_request).to eq(pull_request)
              expect(pipeline.source_sha).to eq(source_sha)
              expect(pipeline.builds.order(:stage_id)
                .map(&:name))
                .to eq(%w[build test pages])
            end
          end

          context 'when external pull request is not specified' do
            let(:pull_request) { nil }

            it 'does not create an external pull request pipeline', :aggregate_failures do
              expect(response).to be_error
              expect(response.message).to eq("External pull request can't be blank and Failed to build the pipeline!")
              expect(pipeline).not_to be_persisted
              expect(pipeline.errors[:base]).to eq(['Failed to build the pipeline!'])
            end
          end
        end
      end
    end

    describe 'Pipelines for merge requests' do
      let(:response) do
        execute_service(
          source: source,
          merge_request: merge_request,
          ref: ref_name,
          source_sha: source_sha,
          target_sha: target_sha
        )
      end

      let(:pipeline) { response.payload }

      before do
        stub_ci_pipeline_yaml_file(YAML.dump(config))
      end

      let(:ref_name) { 'refs/heads/feature' }
      let(:source_sha) { project.commit(ref_name).id }
      let(:target_sha) { nil }

      context 'when source is merge request' do
        let(:source) { :merge_request_event }

        context "when config has merge_requests keywords" do
          let(:config) do
            {
              build: {
                stage: 'build',
                script: 'echo'
              },
              test: {
                stage: 'test',
                script: 'echo',
                only: ['merge_requests']
              },
              pages: {
                stage: 'deploy',
                script: 'echo',
                except: ['merge_requests']
              }
            }
          end

          context 'when merge request is specified' do
            let(:merge_request) do
              create(:merge_request,
                source_project: project,
                source_branch: 'feature',
                target_project: project,
                target_branch: 'master')
            end

            let(:ref_name) { merge_request.ref_path }

            it 'creates a detached merge request pipeline' do
              expect(pipeline).to be_persisted
              expect(pipeline).to be_merge_request_event
              expect(pipeline.merge_request).to eq(merge_request)
              expect(pipeline.builds.order(:stage_id).pluck(:name)).to eq(%w[test])
            end

            it 'persists the specified source sha' do
              expect(pipeline.source_sha).to eq(source_sha)
            end

            it 'does not persist target sha for detached merge request pipeline' do
              expect(pipeline.target_sha).to be_nil
            end

            it 'schedules update for the head pipeline of the merge request' do
              allow(MergeRequests::UpdateHeadPipelineWorker).to receive(:perform_async)

              pipeline

              expect(MergeRequests::UpdateHeadPipelineWorker).to have_received(:perform_async).with('Ci::PipelineCreatedEvent', { 'pipeline_id' => pipeline.id })
            end

            context 'when target sha is specified' do
              let(:target_sha) { merge_request.target_branch_sha }

              it 'persists the target sha' do
                expect(pipeline.target_sha).to eq(target_sha)
              end
            end

            context 'when ref is tag' do
              let(:ref_name) { 'refs/tags/v1.1.0' }

              it 'does not create a merge request pipeline', :aggregate_failures do
                expect(response).to be_error
                expect(response.message).to eq('Tag is not included in the list and Failed to build the pipeline!')
                expect(pipeline).not_to be_persisted
                expect(pipeline.errors[:tag]).to eq(['is not included in the list'])
              end
            end

            context 'when merge request is created from a forked project' do
              let(:merge_request) do
                create(:merge_request,
                  source_project: project,
                  source_branch: 'feature',
                  target_project: target_project,
                  target_branch: 'master')
              end

              let(:ref_name) { 'refs/heads/feature' }
              let!(:project) { fork_project(target_project, nil, repository: true) }
              let!(:target_project) { create(:project, :repository) }
              let!(:user) { create(:user) }

              before do
                project.add_developer(user)
              end

              it 'creates a legacy detached merge request pipeline in the forked project', :sidekiq_might_not_need_inline do
                expect(pipeline).to be_persisted
                expect(project.ci_pipelines).to eq([pipeline])
                expect(target_project.ci_pipelines).to be_empty
              end
            end

            context "when there are no matched jobs" do
              let(:config) do
                {
                  test: {
                    stage: 'test',
                    script: 'echo',
                    except: ['merge_requests']
                  }
                }
              end

              it 'does not create a detached merge request pipeline', :aggregate_failures do
                expect(response).to be_error
                expect(response.message).to eq(sanitize_message(Ci::Pipeline.rules_failure_message))
                expect(pipeline).not_to be_persisted
              end
            end
          end
        end

        context "when config does not have merge_requests keywords" do
          let(:config) do
            {
              build: {
                stage: 'build',
                script: 'echo'
              },
              test: {
                stage: 'test',
                script: 'echo'
              },
              pages: {
                stage: 'deploy',
                script: 'echo'
              }
            }
          end

          context 'when merge request is specified' do
            let(:merge_request) do
              create(:merge_request,
                source_project: project,
                source_branch: Gitlab::Git.ref_name(ref_name),
                target_project: project,
                target_branch: 'master')
            end

            it 'does not create a detached merge request pipeline', :aggregate_failures do
              expect(response).to be_error
              expect(response.message).to eq(sanitize_message(Ci::Pipeline.rules_failure_message))
              expect(pipeline).not_to be_persisted
            end
          end
        end

        context "when config uses regular expression for only keyword" do
          let(:config) do
            {
              build: {
                stage: 'build',
                script: 'echo',
                only: ["/^#{ref_name}$/"]
              }
            }
          end

          context 'when merge request is specified' do
            let(:merge_request) do
              create(:merge_request,
                source_project: project,
                source_branch: Gitlab::Git.ref_name(ref_name),
                target_project: project,
                target_branch: 'master')
            end

            it 'does not create a detached merge request pipeline', :aggregate_failures do
              expect(response).to be_error
              expect(response.message).to eq(sanitize_message(Ci::Pipeline.rules_failure_message))
              expect(pipeline).not_to be_persisted
            end
          end
        end

        context "when config uses variables for only keyword" do
          let(:config) do
            {
              build: {
                stage: 'build',
                script: 'echo',
                only: {
                  variables: %w[$CI]
                }
              }
            }
          end

          context 'when merge request is specified' do
            let(:merge_request) do
              create(:merge_request,
                source_project: project,
                source_branch: Gitlab::Git.ref_name(ref_name),
                target_project: project,
                target_branch: 'master')
            end

            it 'does not create a detached merge request pipeline', :aggregate_failures do
              expect(response).to be_error
              expect(response.message).to eq(sanitize_message(Ci::Pipeline.rules_failure_message))
              expect(pipeline).not_to be_persisted
            end
          end
        end

        context "when config has 'except: [tags]'" do
          let(:config) do
            {
              build: {
                stage: 'build',
                script: 'echo',
                except: ['tags']
              }
            }
          end

          context 'when merge request is specified' do
            let(:merge_request) do
              create(:merge_request,
                source_project: project,
                source_branch: Gitlab::Git.ref_name(ref_name),
                target_project: project,
                target_branch: 'master')
            end

            it 'does not create a detached merge request pipeline', :aggregate_failures do
              expect(response).to be_error
              expect(response.message).to eq(sanitize_message(Ci::Pipeline.rules_failure_message))
              expect(pipeline).not_to be_persisted
            end
          end
        end
      end

      context 'when source is web' do
        let(:source) { :web }
        let(:merge_request) { nil }

        context "when config has merge_requests keywords" do
          let(:config) do
            {
              build: {
                stage: 'build',
                script: 'echo'
              },
              test: {
                stage: 'test',
                script: 'echo',
                only: ['merge_requests']
              },
              pages: {
                stage: 'deploy',
                script: 'echo',
                except: ['merge_requests']
              }
            }
          end

          it 'creates a branch pipeline' do
            expect(pipeline).to be_persisted
            expect(pipeline).to be_web
            expect(pipeline.merge_request).to be_nil
            expect(pipeline.builds.order(:stage_id).pluck(:name)).to eq(%w[build pages])
          end
        end
      end
    end

    context 'when needs is used' do
      let(:response) { execute_service }
      let(:pipeline) { response.payload }

      let(:config) do
        {
          build_a: {
            stage: "build",
            script: "ls",
            only: %w[master]
          },
          test_a: {
            stage: "test",
            script: "ls",
            only: %w[master feature],
            needs: %w[build_a]
          },
          deploy: {
            stage: "deploy",
            script: "ls",
            only: %w[tags]
          }
        }
      end

      before do
        stub_ci_pipeline_yaml_file(YAML.dump(config))
      end

      context 'when pipeline on master is created' do
        let(:ref_name) { 'refs/heads/master' }

        it 'creates a pipeline with build_a and test_a' do
          expect(pipeline).to be_persisted
          expect(pipeline.builds.pluck(:name)).to contain_exactly("build_a", "test_a")
        end

        it 'bulk inserts all needs' do
          expect(Ci::BuildNeed).to receive(:bulk_insert!).and_call_original

          expect(pipeline).to be_persisted
        end
      end

      context 'when pipeline on feature is created' do
        let(:ref_name) { 'refs/heads/feature' }

        shared_examples 'has errors' do
          it 'contains the expected errors', :aggregate_failures do
            expect(pipeline.builds).to be_empty

            error_message = "'test_a' job needs 'build_a' job, but 'build_a' does not exist in the pipeline"
            expect(pipeline.yaml_errors).to include(error_message)
            expect(pipeline.error_messages.map(&:content).first).to include(error_message)
            expect(pipeline.errors[:base].first).to include(error_message)
          end
        end

        context 'when save_on_errors is enabled' do
          let(:response) { execute_service(save_on_errors: true) }
          let(:pipeline) { response.payload }

          it 'does create a pipeline as test_a depends on build_a', :aggregate_failures do
            expect(response).to be_error

            expect(response.message).to include(
              "'test_a' job needs 'build_a' job, but 'build_a' does not exist in the pipeline"
            )

            expect(pipeline).to be_persisted
          end

          it_behaves_like 'has errors'
        end

        context 'when save_on_errors is disabled' do
          let(:response) { execute_service(save_on_errors: false) }
          let(:pipeline) { response.payload }

          it 'does not create a pipeline as test_a depends on build_a', :aggregate_failures do
            expect(response).to be_error
            expect(pipeline).not_to be_persisted
          end

          it_behaves_like 'has errors'
        end
      end

      context 'when pipeline on v1.0.0 is created' do
        let(:ref_name) { 'refs/tags/v1.0.0' }

        it 'does create a pipeline only with deploy' do
          expect(pipeline).to be_persisted
          expect(pipeline.builds.pluck(:name)).to contain_exactly("deploy")
        end
      end
    end

    describe 'pipeline components' do
      let(:components_project) do
        create(:project, :repository, creator: user, namespace: user.namespace)
      end

      let(:component_path) do
        "#{Gitlab.config.gitlab.host}/#{components_project.full_path}/my-component@v0.1"
      end

      let(:template) do
        <<~YAML
          spec:
            inputs:
              stage:
              suffix:
                default: my-job
          ---
          test-$[[ inputs.suffix ]]:
            stage: $[[ inputs.stage ]]
            script: run tests
        YAML
      end

      let(:sha) do
        components_project.repository.create_file(
          user,
          'templates/my-component/template.yml',
          template,
          message: 'Add my first CI component',
          branch_name: 'master'
        )
      end

      let(:config) do
        <<~YAML
          include:
            - component: #{component_path}
              inputs:
                stage: my-stage

          stages:
            - my-stage

          test-1:
            stage: my-stage
            script: run test-1
        YAML
      end

      before do
        stub_ci_pipeline_yaml_file(config)
      end

      context 'when there is no version with specified tag' do
        before do
          components_project.repository.add_tag(user, 'v0.01', sha)
        end

        it 'does not create a pipeline' do
          response = execute_service(save_on_errors: true)

          pipeline = response.payload

          expect(pipeline).to be_persisted
          expect(pipeline.yaml_errors)
            .to include "my-component@v0.1' - content not found"
        end
      end

      context 'when there is a proper revision available' do
        before do
          components_project.repository.add_tag(user, 'v0.1', sha)
        end

        context 'when component is valid' do
          it 'creates a pipeline using a pipeline component' do
            response = execute_service(save_on_errors: true)

            pipeline = response.payload

            expect(pipeline).to be_persisted
            expect(pipeline.yaml_errors).to be_blank
            expect(pipeline.statuses.count).to eq 2
            expect(pipeline.statuses.map(&:name)).to match_array %w[test-1 test-my-job]
          end
        end

        context 'when interpolation is invalid' do
          let(:template) do
            <<~YAML
              spec:
                inputs:
                  stage:
              ---
              test:
                stage: $[[ inputs.stage ]]
                script: rspec --suite $[[ inputs.suite ]]
            YAML
          end

          it 'does not create a pipeline' do
            response = execute_service(save_on_errors: true)

            pipeline = response.payload

            expect(pipeline).to be_persisted
            expect(pipeline.yaml_errors)
              .to include 'unknown interpolation key: `suite`'
          end
        end

        context 'when there is a syntax error in the template' do
          let(:template) do
            <<~YAML
              spec:
                inputs:
                  stage:
              ---
              :test
                stage: $[[ inputs.stage ]]
            YAML
          end

          it 'does not create a pipeline' do
            response = execute_service(save_on_errors: true)

            pipeline = response.payload

            expect(pipeline).to be_persisted
            expect(pipeline.yaml_errors)
              .to include 'mapping values are not allowed'
          end
        end
      end
    end

    # TODO: Remove this test section when include:with is removed as part of https://gitlab.com/gitlab-org/gitlab/-/issues/408369
    describe 'pipeline components using include:with instead of include:inputs' do
      let(:components_project) do
        create(:project, :repository, creator: user, namespace: user.namespace)
      end

      let(:component_path) do
        "#{Gitlab.config.gitlab.host}/#{components_project.full_path}/my-component@v0.1"
      end

      let(:template) do
        <<~YAML
          spec:
            inputs:
              stage:
              suffix:
                default: my-job
          ---
          test-$[[ inputs.suffix ]]:
            stage: $[[ inputs.stage ]]
            script: run tests
        YAML
      end

      let(:sha) do
        components_project.repository.create_file(
          user,
          'templates/my-component/template.yml',
          template,
          message: 'Add my first CI component',
          branch_name: 'master'
        )
      end

      let(:config) do
        <<~YAML
          include:
            - component: #{component_path}
              with:
                stage: my-stage

          stages:
            - my-stage

          test-1:
            stage: my-stage
            script: run test-1
        YAML
      end

      before do
        stub_ci_pipeline_yaml_file(config)
      end

      context 'when there is no version with specified tag' do
        before do
          components_project.repository.add_tag(user, 'v0.01', sha)
        end

        it 'does not create a pipeline' do
          response = execute_service(save_on_errors: true)

          pipeline = response.payload

          expect(pipeline).to be_persisted
          expect(pipeline.yaml_errors)
            .to include "my-component@v0.1' - content not found"
        end
      end

      context 'when there is a proper revision available' do
        before do
          components_project.repository.add_tag(user, 'v0.1', sha)
        end

        context 'when component is valid' do
          it 'creates a pipeline using a pipeline component' do
            response = execute_service(save_on_errors: true)

            pipeline = response.payload

            expect(pipeline).to be_persisted
            expect(pipeline.yaml_errors).to be_blank
            expect(pipeline.statuses.count).to eq 2
            expect(pipeline.statuses.map(&:name)).to match_array %w[test-1 test-my-job]
          end

          context 'when inputs have a description' do
            let(:template) do
              <<~YAML
                spec:
                  inputs:
                    stage:
                    suffix:
                      default: my-job
                      description: description
                ---
                test-$[[ inputs.suffix ]]:
                  stage: $[[ inputs.stage ]]
                  script: run tests
              YAML
            end

            it 'creates a pipeline' do
              response = execute_service(save_on_errors: true)

              pipeline = response.payload

              expect(pipeline).to be_persisted
              expect(pipeline.yaml_errors).to be_blank
            end
          end
        end

        context 'when interpolation is invalid' do
          let(:template) do
            <<~YAML
              spec:
                inputs:
                  stage:
              ---
              test:
                stage: $[[ inputs.stage ]]
                script: rspec --suite $[[ inputs.suite ]]
            YAML
          end

          it 'does not create a pipeline' do
            response = execute_service(save_on_errors: true)

            pipeline = response.payload

            expect(pipeline).to be_persisted
            expect(pipeline.yaml_errors)
              .to include 'unknown interpolation key: `suite`'
          end
        end

        context 'when there is a syntax error in the template' do
          let(:template) do
            <<~YAML
              spec:
                inputs:
                  stage:
              ---
              :test
                stage: $[[ inputs.stage ]]
            YAML
          end

          it 'does not create a pipeline' do
            response = execute_service(save_on_errors: true)

            pipeline = response.payload

            expect(pipeline).to be_persisted
            expect(pipeline.yaml_errors)
              .to include 'mapping values are not allowed'
          end
        end
      end
    end

    unless Gitlab.ee?
      context 'with partition_id param' do
        it 'raises error' do
          expect { execute_service(partition_id: ci_testing_partition_id) }
            .to raise_error(ArgumentError, "Param `partition_id` is not allowed")
        end
      end
    end

    describe 'pipeline creation status updating', :clean_gitlab_redis_shared_state do
      let(:merge_request) do
        create(:merge_request, source_branch: 'feature', target_branch: "master", source_project: project)
      end

      let(:config) do
        {
          test: {
            script: 'ls',
            rules: [{ if: "$CI_PIPELINE_SOURCE == 'merge_request_event'" }]
          }
        }
      end

      before do
        stub_ci_pipeline_yaml_file(config.to_json)
      end

      context 'when the pipeline creation succeeds' do
        it 'updates the status with `succeeded` and the pipeline ID' do
          creation_request = ::Ci::PipelineCreation::Requests.start_for_merge_request(merge_request)

          response = execute_service(
            merge_request: merge_request, pipeline_creation_request: creation_request, source: :merge_request_event
          )

          successful_request = ::Ci::PipelineCreation::Requests.hget(creation_request)
          expect(successful_request['pipeline_id']).to eq(response.payload.id)
          expect(successful_request['status']).to eq(::Ci::PipelineCreation::Requests::SUCCEEDED)
        end
      end

      context 'when the pipeline creation fails' do
        let_it_be_with_reload(:user) { create(:user) }

        it 'updates the status with `failed`' do
          creation_request = ::Ci::PipelineCreation::Requests.start_for_merge_request(merge_request)

          execute_service(
            merge_request: merge_request, pipeline_creation_request: creation_request, source: :merge_request_event
          )

          failed_request = ::Ci::PipelineCreation::Requests.hget(creation_request)
          expect(failed_request['error']).to eq('Insufficient permissions to create a new pipeline')
          expect(failed_request['status']).to eq(::Ci::PipelineCreation::Requests::FAILED)
        end
      end
    end
  end

  describe 'SEQUENCE ordering' do
    it 'has AssignPartition before EvaluatePolicies to be able to set consistent partition_id for policy jobs' do
      assign_partition_index, find_configs_index = indexes_in_sequence(
        Gitlab::Ci::Pipeline::Chain::AssignPartition,
        Gitlab::Ci::Pipeline::Chain::PipelineExecutionPolicies::EvaluatePolicies
      )
      expect(assign_partition_index).to be < find_configs_index
    end

    it 'has EvaluatePolicies before Skip to disallow pipeline skipping with enforced policy jobs' do
      find_configs_index, skip_index = indexes_in_sequence(
        Gitlab::Ci::Pipeline::Chain::PipelineExecutionPolicies::EvaluatePolicies,
        Gitlab::Ci::Pipeline::Chain::Skip
      )
      expect(find_configs_index).to be < skip_index
    end

    it 'has EvaluatePolicies before Config::Content to force the pipeline creation without project CI config' do
      find_configs_index, config_content_index = indexes_in_sequence(
        Gitlab::Ci::Pipeline::Chain::PipelineExecutionPolicies::EvaluatePolicies,
        Gitlab::Ci::Pipeline::Chain::Config::Content
      )
      expect(find_configs_index).to be < config_content_index
    end

    it 'has ApplyPolicies after Populate to ensure that pipeline stages are set' do
      merge_jobs_index, populate_index = indexes_in_sequence(
        Gitlab::Ci::Pipeline::Chain::PipelineExecutionPolicies::ApplyPolicies,
        Gitlab::Ci::Pipeline::Chain::Populate
      )
      expect(merge_jobs_index).to be > populate_index
    end

    it 'has ApplyPolicies before StopDryRun to make policy jobs visible in dry run' do
      merge_jobs_index, stop_dry_run_index = indexes_in_sequence(
        Gitlab::Ci::Pipeline::Chain::PipelineExecutionPolicies::ApplyPolicies,
        Gitlab::Ci::Pipeline::Chain::StopDryRun
      )
      expect(merge_jobs_index).to be < stop_dry_run_index
    end

    private

    def indexes_in_sequence(step1, step2)
      step1_index = described_class::SEQUENCE.find_index(step1)
      step2_index = described_class::SEQUENCE.find_index(step2)
      [step1_index, step2_index]
    end
  end

  describe '#execute_async' do
    it 'queues a worker for pipeline creation' do
      allow(SecureRandom).to receive(:uuid).and_return('test-id')

      expect(CreatePipelineWorker).to receive(:perform_async).with(
        project.id, user.id, project.default_branch, 'web', { 'save_on_errors' => false },
        {
          'pipeline_creation_request' => {
            'key' => Ci::PipelineCreation::Requests.request_key(project, 'test-id'),
            'id' => 'test-id'
          }
        }
      )

      service = described_class.new(project, user, ref: project.default_branch)
      response = service.execute_async('web', { save_on_errors: false })

      expect(response).to be_success
      expect(response.payload).to eq('test-id')
    end
  end
end
