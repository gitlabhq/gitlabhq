# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService do
  include ProjectForksHelper

  let_it_be(:project, reload: true) { create(:project, :repository) }
  let_it_be(:user, reload: true) { project.owner }

  let(:ref_name) { 'refs/heads/master' }

  before do
    stub_ci_pipeline_yaml_file(gitlab_ci_yaml)
  end

  describe '#execute' do
    # rubocop:disable Metrics/ParameterLists
    def execute_service(
      source: :push,
      after: project.commit.id,
      message: 'Message',
      ref: ref_name,
      trigger_request: nil,
      variables_attributes: nil,
      merge_request: nil,
      external_pull_request: nil,
      push_options: nil,
      source_sha: nil,
      target_sha: nil,
      save_on_errors: true)
      params = { ref: ref,
                 before: '00000000',
                 after: after,
                 commits: [{ message: message }],
                 variables_attributes: variables_attributes,
                 push_options: push_options,
                 source_sha: source_sha,
                 target_sha: target_sha }

      described_class.new(project, user, params).execute(source,
        save_on_errors: save_on_errors,
        trigger_request: trigger_request,
        merge_request: merge_request,
        external_pull_request: external_pull_request) do |pipeline|
        yield(pipeline) if block_given?
      end
    end
    # rubocop:enable Metrics/ParameterLists

    context 'valid params' do
      let(:pipeline) { execute_service }

      let(:pipeline_on_previous_commit) do
        execute_service(
          after: previous_commit_sha_from_ref('master')
        )
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
          .with({ source: 'push' }, 5)
      end

      it 'tracks included template usage' do
        expect_next_instance_of(Gitlab::Ci::Pipeline::Chain::TemplateUsage) do |instance|
          expect(instance).to receive(:perform!)
        end

        execute_service
      end

      context 'when merge requests already exist for this source branch' do
        let(:merge_request_1) do
          create(:merge_request, source_branch: 'feature', target_branch: "master", source_project: project)
        end

        let(:merge_request_2) do
          create(:merge_request, source_branch: 'feature', target_branch: "v1.1.0", source_project: project)
        end

        context 'when related merge request is already merged' do
          let!(:merged_merge_request) do
            create(:merge_request, source_branch: 'master', target_branch: "branch_2", source_project: project, state: 'merged')
          end

          it 'does not schedule update head pipeline job' do
            expect(UpdateHeadPipelineForMergeRequestWorker).not_to receive(:perform_async).with(merged_merge_request.id)

            execute_service
          end
        end

        context 'when the head pipeline sha equals merge request sha' do
          it 'updates head pipeline of each merge request', :sidekiq_might_not_need_inline do
            merge_request_1
            merge_request_2

            head_pipeline = execute_service(ref: 'feature', after: nil)

            expect(merge_request_1.reload.head_pipeline).to eq(head_pipeline)
            expect(merge_request_2.reload.head_pipeline).to eq(head_pipeline)
          end
        end

        context 'when the head pipeline sha does not equal merge request sha' do
          it 'does not update the head piepeline of MRs' do
            merge_request_1
            merge_request_2

            allow_any_instance_of(Ci::Pipeline).to receive(:latest?).and_return(true)

            expect { execute_service(after: 'ae73cb07c9eeaf35924a10f713b364d32b2dd34f') }.not_to raise_error

            last_pipeline = Ci::Pipeline.last

            expect(merge_request_1.reload.head_pipeline).not_to eq(last_pipeline)
            expect(merge_request_2.reload.head_pipeline).not_to eq(last_pipeline)
          end
        end

        context 'when there is no pipeline for source branch' do
          it "does not update merge request head pipeline" do
            merge_request = create(:merge_request, source_branch: 'feature',
                                                   target_branch: "branch_1",
                                                   source_project: project)

            head_pipeline = execute_service

            expect(merge_request.reload.head_pipeline).not_to eq(head_pipeline)
          end
        end

        context 'when merge request target project is different from source project' do
          let!(:project) { fork_project(target_project, nil, repository: true) }
          let!(:target_project) { create(:project, :repository) }
          let!(:user) { create(:user) }

          before do
            project.add_developer(user)
          end

          it 'updates head pipeline for merge request', :sidekiq_might_not_need_inline do
            merge_request = create(:merge_request, source_branch: 'feature',
                                                   target_branch: "master",
                                                   source_project: project,
                                                   target_project: target_project)

            head_pipeline = execute_service(ref: 'feature', after: nil)

            expect(merge_request.reload.head_pipeline).to eq(head_pipeline)
          end
        end

        context 'when the pipeline is not the latest for the branch' do
          it 'does not update merge request head pipeline' do
            merge_request = create(:merge_request, source_branch: 'master',
                                                   target_branch: "branch_1",
                                                   source_project: project)

            allow_any_instance_of(MergeRequest)
              .to receive(:find_actual_head_pipeline) { }

            execute_service

            expect(merge_request.reload.head_pipeline).to be_nil
          end
        end

        context 'when pipeline has errors' do
          before do
            stub_ci_pipeline_yaml_file('some invalid syntax')
          end

          it 'updates merge request head pipeline reference', :sidekiq_might_not_need_inline do
            merge_request = create(:merge_request, source_branch: 'master',
                                                   target_branch: 'feature',
                                                   source_project: project)

            head_pipeline = execute_service

            expect(head_pipeline).to be_persisted
            expect(head_pipeline.yaml_errors).to be_present
            expect(head_pipeline.messages).to be_present
            expect(merge_request.reload.head_pipeline).to eq head_pipeline
          end
        end

        context 'when pipeline has been skipped' do
          before do
            allow_any_instance_of(Ci::Pipeline)
              .to receive(:git_commit_message)
              .and_return('some commit [ci skip]')
          end

          it 'updates merge request head pipeline', :sidekiq_might_not_need_inline do
            merge_request = create(:merge_request, source_branch: 'master',
                                                   target_branch: 'feature',
                                                   source_project: project)

            head_pipeline = execute_service

            expect(head_pipeline).to be_skipped
            expect(head_pipeline).to be_persisted
            expect(merge_request.reload.head_pipeline).to eq head_pipeline
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
          head_pipeline = execute_service

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
          )
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
              pipeline = execute_service

              expect(pipeline.builds.find_by(name: 'rspec').interruptible).to be_nil
            end
          end

          context 'set to true' do
            before do
              config = YAML.dump(rspec: { script: 'echo', interruptible: true })
              stub_ci_pipeline_yaml_file(config)
            end

            it 'is cancelable' do
              pipeline = execute_service

              expect(pipeline.builds.find_by(name: 'rspec').interruptible).to be_truthy
            end
          end

          context 'set to false' do
            before do
              config = YAML.dump(rspec: { script: 'echo', interruptible: false })
              stub_ci_pipeline_yaml_file(config)
            end

            it 'is not cancelable' do
              pipeline = execute_service

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
                .pluck(:name, 'ci_builds_metadata.interruptible')

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
              it 'cancels running outdated pipelines', :sidekiq_might_not_need_inline do
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
              it 'cancels running outdated pipelines', :sidekiq_might_not_need_inline do
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
        expect(execute_service).to be_persisted
      end

      it "creates commit if there is no appropriate job but deploy job has right ref setting" do
        config = YAML.dump({ deploy: { script: "ls", only: ["master"] } })
        stub_ci_pipeline_yaml_file(config)

        expect(execute_service).to be_persisted
      end
    end

    it 'skips creating pipeline for refs without .gitlab-ci.yml' do
      stub_ci_pipeline_yaml_file(nil)

      expect(execute_service).not_to be_persisted
      expect(Ci::Pipeline.count).to eq(0)
      expect(Namespaces::OnboardingPipelineCreatedWorker).not_to receive(:perform_async)
    end

    shared_examples 'a failed pipeline' do
      it 'creates failed pipeline' do
        stub_ci_pipeline_yaml_file(ci_yaml)

        pipeline = execute_service(message: message)

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
          pipeline = execute_service
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
          pipeline = execute_service
          expect(pipeline).to be_auto_devops_source
          expect(pipeline.builds.map(&:name)).to match_array(%w[brakeman-sast build code_quality eslint-sast secret_detection semgrep-sast test])
        end
      end

      context 'when config is not found' do
        before do
          stub_ci_pipeline_yaml_file(nil)
        end

        it 'attaches errors to the pipeline' do
          pipeline = execute_service

          expect(pipeline.errors.full_messages).to eq ['Missing CI config file']
          expect(pipeline).not_to be_persisted
        end
      end

      context 'when an unexpected error is raised' do
        before do
          expect(Gitlab::Ci::YamlProcessor).to receive(:new)
            .and_raise(RuntimeError, 'undefined failure')
        end

        it 'saves error in pipeline' do
          pipeline = execute_service

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
                name: ruby:2.7
                ports:
                  - 80
            EOS
          end

          it_behaves_like 'a failed pipeline'
        end

        context 'in the job image' do
          let(:ci_yaml) do
            <<-EOS
              image: ruby:2.7

              test:
                script: rspec
                image:
                  name: ruby:2.7
                  ports:
                    - 80
            EOS
          end

          it_behaves_like 'a failed pipeline'
        end

        context 'in the service' do
          let(:ci_yaml) do
            <<-EOS
              image: ruby:2.7

              test:
                script: rspec
                image: ruby:2.7
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
        pipeline = execute_service

        expect(pipeline.yaml_errors).to include('Undefined error')
      end

      it 'logs error' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).and_call_original

        execute_service
      end
    end

    context 'when commit contains a [ci skip] directive' do
      let(:message) { "some message[ci skip]" }

      ci_messages = [
        "some message[ci skip]",
        "some message[skip ci]",
        "some message[CI SKIP]",
        "some message[SKIP CI]",
        "some message[ci_skip]",
        "some message[skip_ci]",
        "some message[ci-skip]",
        "some message[skip-ci]"
      ]

      before do
        allow_any_instance_of(Ci::Pipeline).to receive(:git_commit_message) { message }
      end

      ci_messages.each do |ci_message|
        it "skips builds creation if the commit message is #{ci_message}" do
          pipeline = execute_service(message: ci_message)

          expect(pipeline).to be_persisted
          expect(pipeline.builds.any?).to be false
          expect(pipeline.status).to eq("skipped")
        end
      end

      shared_examples 'creating a pipeline' do
        it 'does not skip pipeline creation' do
          allow_any_instance_of(Ci::Pipeline).to receive(:git_commit_message) { commit_message }

          pipeline = execute_service(message: commit_message)

          expect(pipeline).to be_persisted
          expect(pipeline.builds.first.name).to eq("rspec")
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
        let(:ci_yaml) { 'invalid: file: fiile' }

        it_behaves_like 'a failed pipeline'
      end
    end

    context 'when push options contain ci.skip' do
      let(:push_options) do
        { 'ci' => { 'skip' => true } }
      end

      it 'creates a pipline in the skipped state' do
        pipeline = execute_service(push_options: push_options)

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

      it 'does not create a new pipeline' do
        result = execute_service

        expect(result).not_to be_persisted
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

        it 'rewinds iid' do
          result = execute_service

          expect(result).not_to be_persisted
          expect(internal_id.last_value).to eq(0)
        end
      end
    end

    context 'with manual actions' do
      before do
        config = YAML.dump({ deploy: { script: 'ls', when: 'manual' } })
        stub_ci_pipeline_yaml_file(config)
      end

      it 'does not create a new pipeline', :sidekiq_inline do
        result = execute_service

        expect(result).to be_persisted
        expect(result.manual_actions).not_to be_empty
      end
    end

    context 'with environment' do
      before do
        config = YAML.dump(
          deploy: {
            environment: { name: "review/$CI_COMMIT_REF_NAME" },
            script: 'ls',
            tags: ['hello']
          })

        stub_ci_pipeline_yaml_file(config)
      end

      it 'creates the environment with tags' do
        result = execute_service

        expect(result).to be_persisted
        expect(Environment.find_by(name: "review/master")).to be_present
        expect(result.builds.first.tag_list).to contain_exactly('hello')
        expect(result.builds.first.deployment).to be_persisted
        expect(result.builds.first.deployment.deployable).to be_a(Ci::Build)
      end
    end

    context 'with environment with auto_stop_in' do
      before do
        config = YAML.dump(
          deploy: {
            environment: { name: "review/$CI_COMMIT_REF_NAME", auto_stop_in: '1 day' },
            script: 'ls'
          })

        stub_ci_pipeline_yaml_file(config)
      end

      it 'creates the environment with auto stop in' do
        result = execute_service

        expect(result).to be_persisted
        expect(result.builds.first.options[:environment][:auto_stop_in]).to eq('1 day')
      end
    end

    context 'with environment name including persisted variables' do
      before do
        config = YAML.dump(
          deploy: {
            environment: { name: "review/id1$CI_PIPELINE_ID/id2$CI_BUILD_ID" },
            script: 'ls'
          }
        )

        stub_ci_pipeline_yaml_file(config)
      end

      it 'skipps persisted variables in environment name' do
        result = execute_service

        expect(result).to be_persisted
        expect(Environment.find_by(name: "review/id1/id2")).to be_present
      end
    end

    context 'environment with Kubernetes configuration' do
      let(:kubernetes_namespace) { 'custom-namespace' }

      before do
        config = YAML.dump(
          deploy: {
            environment: {
              name: "environment-name",
              kubernetes: { namespace: kubernetes_namespace }
            },
            script: 'ls'
          }
        )

        stub_ci_pipeline_yaml_file(config)
      end

      it 'stores the requested namespace' do
        result = execute_service
        build = result.builds.first

        expect(result).to be_persisted
        expect(build.options.dig(:environment, :kubernetes, :namespace)).to eq(kubernetes_namespace)
      end
    end

    context 'when environment with invalid name' do
      before do
        config = YAML.dump(deploy: { environment: { name: 'name,with,commas' }, script: 'ls' })
        stub_ci_pipeline_yaml_file(config)
      end

      it 'does not create an environment' do
        expect do
          result = execute_service

          expect(result).to be_persisted
        end.not_to change { Environment.count }
      end
    end

    context 'when environment with duplicate names' do
      let(:ci_yaml) do
        {
          deploy: { environment: { name: 'production' }, script: 'ls' },
          deploy_2: { environment: { name: 'production' }, script: 'ls' }
        }
      end

      before do
        stub_ci_pipeline_yaml_file(YAML.dump(ci_yaml))
      end

      it 'creates a pipeline with the environment' do
        result = execute_service

        expect(result).to be_persisted
        expect(Environment.find_by(name: 'production')).to be_present
        expect(result.builds.first.deployment).to be_persisted
        expect(result.builds.first.deployment.deployable).to be_a(Ci::Build)
      end
    end

    context 'when builds with auto-retries are configured' do
      let(:pipeline)  { execute_service }
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
          result = execute_service
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
            result = execute_service

            expect(result).to be_persisted
            expect(project.resource_groups.exists?(key: 'master-test')).to eq(true)
          end
        end
      end
    end

    context 'with timeout' do
      context 'when builds with custom timeouts are configured' do
        before do
          config = YAML.dump(rspec: { script: 'rspec', timeout: '2m 3s' })
          stub_ci_pipeline_yaml_file(config)
        end

        it 'correctly creates builds with custom timeout value configured' do
          pipeline = execute_service

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
          pipeline = execute_service
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

        it 'does not create a pipeline' do
          expect(execute_service).not_to be_persisted
          expect(Ci::Pipeline.count).to eq(0)
        end
      end

      context 'when user is maintainer' do
        let(:pipeline) { execute_service }

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
        let(:trigger_request) { create(:ci_trigger_request) }

        it 'does not create a pipeline' do
          expect(execute_service(trigger_request: trigger_request))
            .not_to be_persisted
          expect(Ci::Pipeline.count).to eq(0)
        end
      end

      context 'when trigger belongs to a developer' do
        let(:user) { create(:user) }
        let(:trigger) { create(:ci_trigger, owner: user) }
        let(:trigger_request) { create(:ci_trigger_request, trigger: trigger) }

        before do
          project.add_developer(user)
        end

        it 'does not create a pipeline' do
          expect(execute_service(trigger_request: trigger_request))
            .not_to be_persisted
          expect(Ci::Pipeline.count).to eq(0)
        end
      end

      context 'when trigger belongs to a maintainer' do
        let(:user) { create(:user) }
        let(:trigger) { create(:ci_trigger, owner: user) }
        let(:trigger_request) { create(:ci_trigger_request, trigger: trigger) }

        before do
          project.add_maintainer(user)
        end

        it 'creates a pipeline' do
          expect(execute_service(trigger_request: trigger_request))
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
        config = YAML.dump(test: { script: 'test', only: ['branches'] },
                           deploy: { script: 'deploy', only: ['tags'] })

        stub_ci_pipeline_yaml_file(config)
      end

      it 'creates a tagged pipeline' do
        pipeline = execute_service(ref: 'v1.0.0')

        expect(pipeline.tag?).to be true
      end
    end

    context 'when pipeline variables are specified' do
      let(:variables_attributes) do
        [{ key: 'first', secret_value: 'world' },
         { key: 'second', secret_value: 'second_world' }]
      end

      subject { execute_service(variables_attributes: variables_attributes) }

      it 'creates a pipeline with specified variables' do
        expect(subject.variables.map { |var| var.slice(:key, :secret_value) })
          .to eq variables_attributes.map(&:with_indifferent_access)
      end
    end

    context 'when pipeline has a job with environment' do
      let(:pipeline) { execute_service }

      before do
        stub_ci_pipeline_yaml_file(YAML.dump(config))
      end

      context 'when environment name is valid' do
        let(:config) do
          {
            review_app: {
              script: 'deploy',
              environment: {
                name: 'review/${CI_COMMIT_REF_NAME}',
                url: 'http://${CI_COMMIT_REF_SLUG}-staging.example.com'
              }
            }
          }
        end

        it 'has a job with environment' do
          expect(pipeline.builds.count).to eq(1)
          expect(pipeline.builds.first.persisted_environment.name).to eq('review/master')
          expect(pipeline.builds.first.deployment).to be_created
        end
      end

      context 'when environment name is invalid' do
        let(:config) do
          {
            'job:deploy-to-test-site': {
              script: 'deploy',
              environment: {
                name: '${CI_JOB_NAME}',
                url: 'https://$APP_URL'
              }
            }
          }
        end

        it 'has a job without environment' do
          expect(pipeline.builds.count).to eq(1)
          expect(pipeline.builds.first.persisted_environment).to be_nil
          expect(pipeline.builds.first.deployment).to be_nil
        end
      end
    end

    describe 'Pipeline for external pull requests' do
      let(:pipeline) do
        execute_service(source: source,
                        external_pull_request: pull_request,
                        ref: ref_name,
                        source_sha: source_sha,
                        target_sha: target_sha)
      end

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

              it 'does not create an extrnal pull request pipeline' do
                expect(pipeline).not_to be_persisted
                expect(pipeline.errors[:tag]).to eq(["is not included in the list"])
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

              it 'does not create a detached merge request pipeline' do
                expect(pipeline).not_to be_persisted
                expect(pipeline.errors[:base]).to eq(["No stages / jobs for this pipeline."])
              end
            end
          end

          context 'when external pull request is not specified' do
            let(:pull_request) { nil }

            it 'does not create an external pull request pipeline' do
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

            it 'does not create an external pull request pipeline' do
              expect(pipeline).not_to be_persisted

              expect(pipeline.errors[:base])
                .to eq(['Failed to build the pipeline!'])
            end
          end
        end
      end
    end

    describe 'Pipelines for merge requests' do
      let(:pipeline) do
        execute_service(source: source,
                        merge_request: merge_request,
                        ref: ref_name,
                        source_sha: source_sha,
                        target_sha: target_sha)
      end

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
              expect(UpdateHeadPipelineForMergeRequestWorker)
                .to receive(:perform_async).with(merge_request.id)

              pipeline
            end

            it 'schedules a namespace onboarding create action worker' do
              expect(Namespaces::OnboardingPipelineCreatedWorker)
                .to receive(:perform_async).with(project.namespace_id)

              pipeline
            end

            context 'when target sha is specified' do
              let(:target_sha) { merge_request.target_branch_sha }

              it 'persists the target sha' do
                expect(pipeline.target_sha).to eq(target_sha)
              end
            end

            context 'when ref is tag' do
              let(:ref_name) { 'refs/tags/v1.1.0' }

              it 'does not create a merge request pipeline' do
                expect(pipeline).not_to be_persisted
                expect(pipeline.errors[:tag]).to eq(["is not included in the list"])
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

              it 'does not create a detached merge request pipeline' do
                expect(pipeline).not_to be_persisted
                expect(pipeline.errors[:base]).to eq(["No stages / jobs for this pipeline."])
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

            it 'does not create a detached merge request pipeline' do
              expect(pipeline).not_to be_persisted

              expect(pipeline.errors[:base])
                .to eq(['No stages / jobs for this pipeline.'])
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

            it 'does not create a detached merge request pipeline' do
              expect(pipeline).not_to be_persisted

              expect(pipeline.errors[:base])
                .to eq(['No stages / jobs for this pipeline.'])
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
                  variables: %w($CI)
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

            it 'does not create a detached merge request pipeline' do
              expect(pipeline).not_to be_persisted

              expect(pipeline.errors[:base])
                .to eq(['No stages / jobs for this pipeline.'])
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

            it 'does not create a detached merge request pipeline' do
              expect(pipeline).not_to be_persisted

              expect(pipeline.errors[:base])
                .to eq(['No stages / jobs for this pipeline.'])
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
      let(:pipeline) { execute_service }

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
          it 'contains the expected errors' do
            expect(pipeline.builds).to be_empty

            error_message = "'test_a' job needs 'build_a' job, but it was not added to the pipeline"
            expect(pipeline.yaml_errors).to eq(error_message)
            expect(pipeline.error_messages.map(&:content)).to contain_exactly(error_message)
            expect(pipeline.errors[:base]).to contain_exactly(error_message)
          end
        end

        context 'when save_on_errors is enabled' do
          let(:pipeline) { execute_service(save_on_errors: true) }

          it 'does create a pipeline as test_a depends on build_a' do
            expect(pipeline).to be_persisted
          end

          it_behaves_like 'has errors'
        end

        context 'when save_on_errors is disabled' do
          let(:pipeline) { execute_service(save_on_errors: false) }

          it 'does not create a pipeline as test_a depends on build_a' do
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

    context 'when rules are used' do
      let(:ref_name)    { 'refs/heads/master' }
      let(:pipeline)    { execute_service }
      let(:build_names) { pipeline.builds.pluck(:name) }
      let(:regular_job) { find_job('regular-job') }
      let(:rules_job)   { find_job('rules-job') }
      let(:delayed_job) { find_job('delayed-job') }

      shared_examples 'rules jobs are excluded' do
        it 'only persists the job without rules' do
          expect(pipeline).to be_persisted
          expect(regular_job).to be_persisted
          expect(rules_job).to be_nil
          expect(delayed_job).to be_nil
        end
      end

      def find_job(name)
        pipeline.builds.find_by(name: name)
      end

      before do
        stub_ci_pipeline_yaml_file(config)
        allow_any_instance_of(Ci::BuildScheduleWorker).to receive(:perform).and_return(true)
      end

      context 'with simple if: clauses' do
        let(:config) do
          <<-EOY
            regular-job:
              script: 'echo Hello, World!'

            master-job:
              script: "echo hello world, $CI_COMMIT_REF_NAME"
              rules:
                - if: $CI_COMMIT_REF_NAME == "nonexistant-branch"
                  when: never
                - if: $CI_COMMIT_REF_NAME =~ /master/
                  when: manual

            negligible-job:
              script: "exit 1"
              rules:
                - if: $CI_COMMIT_REF_NAME =~ /master/
                  allow_failure: true

            delayed-job:
              script: "echo See you later, World!"
              rules:
                - if: $CI_COMMIT_REF_NAME =~ /master/
                  when: delayed
                  start_in: 1 hour

            never-job:
              script: "echo Goodbye, World!"
              rules:
                - if: $CI_COMMIT_REF_NAME
                  when: never
          EOY
        end

        context 'with matches' do
          it 'creates a pipeline with the vanilla and manual jobs' do
            expect(pipeline).to be_persisted
            expect(build_names).to contain_exactly(
              'regular-job', 'delayed-job', 'master-job', 'negligible-job'
            )
          end

          it 'assigns job:when values to the builds' do
            expect(find_job('regular-job').when).to eq('on_success')
            expect(find_job('master-job').when).to eq('manual')
            expect(find_job('negligible-job').when).to eq('on_success')
            expect(find_job('delayed-job').when).to eq('delayed')
          end

          it 'assigns job:allow_failure values to the builds' do
            expect(find_job('regular-job').allow_failure).to eq(false)
            expect(find_job('master-job').allow_failure).to eq(false)
            expect(find_job('negligible-job').allow_failure).to eq(true)
            expect(find_job('delayed-job').allow_failure).to eq(false)
          end

          it 'assigns start_in for delayed jobs' do
            expect(delayed_job.options[:start_in]).to eq('1 hour')
          end
        end

        context 'with no matches' do
          let(:ref_name) { 'refs/heads/feature' }

          it_behaves_like 'rules jobs are excluded'
        end
      end

      context 'with complex if: clauses' do
        let(:config) do
          <<-EOY
            regular-job:
              script: 'echo Hello, World!'
              rules:
                - if: $VAR == 'present' && $OTHER || $CI_COMMIT_REF_NAME
                  when: manual
                  allow_failure: true
          EOY
        end

        it 'matches the first rule' do
          expect(pipeline).to be_persisted
          expect(build_names).to contain_exactly('regular-job')
          expect(regular_job.when).to eq('manual')
          expect(regular_job.allow_failure).to eq(true)
        end
      end

      context 'with changes:' do
        let(:config) do
          <<-EOY
            regular-job:
              script: 'echo Hello, World!'

            rules-job:
              script: "echo hello world, $CI_COMMIT_REF_NAME"
              rules:
                - changes:
                  - README.md
                  when: manual
                - changes:
                  - app.rb
                  when: on_success

            delayed-job:
              script: "echo See you later, World!"
              rules:
                - changes:
                  - README.md
                  when: delayed
                  start_in: 4 hours

            negligible-job:
              script: "can be failed sometimes"
              rules:
                - changes:
                  - README.md
                  allow_failure: true

            README:
              script: "I use variables for changes!"
              rules:
                - changes:
                  - $CI_JOB_NAME*
          EOY
        end

        context 'and matches' do
          before do
            allow_any_instance_of(Ci::Pipeline)
              .to receive(:modified_paths).and_return(%w[README.md])
          end

          it 'creates five jobs' do
            expect(pipeline).to be_persisted
            expect(build_names)
              .to contain_exactly('regular-job', 'rules-job', 'delayed-job', 'negligible-job', 'README')
          end

          it 'sets when: for all jobs' do
            expect(regular_job.when).to eq('on_success')
            expect(rules_job.when).to eq('manual')
            expect(delayed_job.when).to eq('delayed')
            expect(delayed_job.options[:start_in]).to eq('4 hours')
          end

          it 'sets allow_failure: for negligible job' do
            expect(find_job('negligible-job').allow_failure).to eq(true)
          end
        end

        context 'and matches the second rule' do
          before do
            allow_any_instance_of(Ci::Pipeline)
              .to receive(:modified_paths).and_return(%w[app.rb])
          end

          it 'includes both jobs' do
            expect(pipeline).to be_persisted
            expect(build_names).to contain_exactly('regular-job', 'rules-job')
          end

          it 'sets when: for the created rules job based on the second clause' do
            expect(regular_job.when).to eq('on_success')
            expect(rules_job.when).to eq('on_success')
          end
        end

        context 'and does not match' do
          before do
            allow_any_instance_of(Ci::Pipeline)
              .to receive(:modified_paths).and_return(%w[useless_script.rb])
          end

          it_behaves_like 'rules jobs are excluded'

          it 'sets when: for the created job' do
            expect(regular_job.when).to eq('on_success')
          end
        end
      end

      context 'with mixed if: and changes: rules' do
        let(:config) do
          <<-EOY
            regular-job:
              script: 'echo Hello, World!'

            rules-job:
              script: "echo hello world, $CI_COMMIT_REF_NAME"
              allow_failure: true
              rules:
                - changes:
                  - README.md
                  when: manual
                - if: $CI_COMMIT_REF_NAME == "master"
                  when: on_success
                  allow_failure: false

            delayed-job:
              script: "echo See you later, World!"
              rules:
                - changes:
                  - README.md
                  when: delayed
                  start_in: 4 hours
                  allow_failure: true
                - if: $CI_COMMIT_REF_NAME == "master"
                  when: delayed
                  start_in: 1 hour
          EOY
        end

        context 'and changes: matches before if' do
          before do
            allow_any_instance_of(Ci::Pipeline)
              .to receive(:modified_paths).and_return(%w[README.md])
          end

          it 'creates two jobs' do
            expect(pipeline).to be_persisted
            expect(build_names)
              .to contain_exactly('regular-job', 'rules-job', 'delayed-job')
          end

          it 'sets when: for all jobs' do
            expect(regular_job.when).to eq('on_success')
            expect(rules_job.when).to eq('manual')
            expect(delayed_job.when).to eq('delayed')
            expect(delayed_job.options[:start_in]).to eq('4 hours')
          end

          it 'sets allow_failure: for all jobs' do
            expect(regular_job.allow_failure).to eq(false)
            expect(rules_job.allow_failure).to eq(true)
            expect(delayed_job.allow_failure).to eq(true)
          end
        end

        context 'and if: matches after changes' do
          it 'includes both jobs' do
            expect(pipeline).to be_persisted
            expect(build_names).to contain_exactly('regular-job', 'rules-job', 'delayed-job')
          end

          it 'sets when: for the created rules job based on the second clause' do
            expect(regular_job.when).to eq('on_success')
            expect(rules_job.when).to eq('on_success')
            expect(delayed_job.when).to eq('delayed')
            expect(delayed_job.options[:start_in]).to eq('1 hour')
          end
        end

        context 'and does not match' do
          let(:ref_name) { 'refs/heads/wip' }

          it_behaves_like 'rules jobs are excluded'

          it 'sets when: for the created job' do
            expect(regular_job.when).to eq('on_success')
          end
        end
      end

      context 'with mixed if: and changes: clauses' do
        let(:config) do
          <<-EOY
            regular-job:
              script: 'echo Hello, World!'

            rules-job:
              script: "echo hello world, $CI_COMMIT_REF_NAME"
              rules:
                - if: $CI_COMMIT_REF_NAME =~ /master/
                  changes: [README.md]
                  when: on_success
                  allow_failure: true
                - if: $CI_COMMIT_REF_NAME =~ /master/
                  changes: [app.rb]
                  when: manual
          EOY
        end

        context 'with if matches and changes matches' do
          before do
            allow_any_instance_of(Ci::Pipeline)
              .to receive(:modified_paths).and_return(%w[app.rb])
          end

          it 'persists all jobs' do
            expect(pipeline).to be_persisted
            expect(regular_job).to be_persisted
            expect(rules_job).to be_persisted
            expect(rules_job.when).to eq('manual')
            expect(rules_job.allow_failure).to eq(false)
          end
        end

        context 'with if matches and no change matches' do
          it_behaves_like 'rules jobs are excluded'
        end

        context 'with change matches and no if matches' do
          let(:ref_name) { 'refs/heads/feature' }

          before do
            allow_any_instance_of(Ci::Pipeline)
              .to receive(:modified_paths).and_return(%w[README.md])
          end

          it_behaves_like 'rules jobs are excluded'
        end

        context 'and no matches' do
          let(:ref_name) { 'refs/heads/feature' }

          it_behaves_like 'rules jobs are excluded'
        end
      end

      context 'with complex if: allow_failure usages' do
        let(:config) do
          <<-EOY
            job-1:
              script: "exit 1"
              allow_failure: true
              rules:
                - if: $CI_COMMIT_REF_NAME =~ /master/
                  allow_failure: false

            job-2:
              script: "exit 1"
              allow_failure: true
              rules:
                - if: $CI_COMMIT_REF_NAME =~ /nonexistant-branch/
                  allow_failure: false

            job-3:
              script: "exit 1"
              rules:
                - if: $CI_COMMIT_REF_NAME =~ /nonexistant-branch/
                  allow_failure: true

            job-4:
              script: "exit 1"
              rules:
                - if: $CI_COMMIT_REF_NAME =~ /master/
                  allow_failure: false

            job-5:
              script: "exit 1"
              allow_failure: false
              rules:
                - if: $CI_COMMIT_REF_NAME =~ /master/
                  allow_failure: true

            job-6:
              script: "exit 1"
              rules:
                - if: $CI_COMMIT_REF_NAME =~ /nonexistant-branch/
                  allow_failure: false
                - allow_failure: true
          EOY
        end

        it 'creates a pipeline' do
          expect(pipeline).to be_persisted
          expect(build_names).to contain_exactly('job-1', 'job-4', 'job-5', 'job-6')
        end

        it 'assigns job:allow_failure values to the builds' do
          expect(find_job('job-1').allow_failure).to eq(false)
          expect(find_job('job-4').allow_failure).to eq(false)
          expect(find_job('job-5').allow_failure).to eq(true)
          expect(find_job('job-6').allow_failure).to eq(true)
        end
      end

      context 'with complex if: allow_failure & when usages' do
        let(:config) do
          <<-EOY
            job-1:
              script: "exit 1"
              rules:
                - if: $CI_COMMIT_REF_NAME =~ /master/
                  when: manual

            job-2:
              script: "exit 1"
              rules:
                - if: $CI_COMMIT_REF_NAME =~ /master/
                  when: manual
                  allow_failure: true

            job-3:
              script: "exit 1"
              allow_failure: true
              rules:
                - if: $CI_COMMIT_REF_NAME =~ /master/
                  when: manual

            job-4:
              script: "exit 1"
              allow_failure: true
              rules:
                - if: $CI_COMMIT_REF_NAME =~ /master/
                  when: manual
                  allow_failure: false

            job-5:
              script: "exit 1"
              rules:
                - if: $CI_COMMIT_REF_NAME =~ /nonexistant-branch/
                  when: manual
                  allow_failure: false
                - when: always
                  allow_failure: true

            job-6:
              script: "exit 1"
              allow_failure: false
              rules:
                - if: $CI_COMMIT_REF_NAME =~ /master/
                  when: manual

            job-7:
              script: "exit 1"
              allow_failure: false
              rules:
                - if: $CI_COMMIT_REF_NAME =~ /nonexistant-branch/
                  when: manual
                - when: :on_failure
                  allow_failure: true
          EOY
        end

        it 'creates a pipeline' do
          expect(pipeline).to be_persisted
          expect(build_names).to contain_exactly(
            'job-1', 'job-2', 'job-3', 'job-4', 'job-5', 'job-6', 'job-7'
          )
        end

        it 'assigns job:allow_failure values to the builds' do
          expect(find_job('job-1').allow_failure).to eq(false)
          expect(find_job('job-2').allow_failure).to eq(true)
          expect(find_job('job-3').allow_failure).to eq(true)
          expect(find_job('job-4').allow_failure).to eq(false)
          expect(find_job('job-5').allow_failure).to eq(true)
          expect(find_job('job-6').allow_failure).to eq(false)
          expect(find_job('job-7').allow_failure).to eq(true)
        end

        it 'assigns job:when values to the builds' do
          expect(find_job('job-1').when).to eq('manual')
          expect(find_job('job-2').when).to eq('manual')
          expect(find_job('job-3').when).to eq('manual')
          expect(find_job('job-4').when).to eq('manual')
          expect(find_job('job-5').when).to eq('always')
          expect(find_job('job-6').when).to eq('manual')
          expect(find_job('job-7').when).to eq('on_failure')
        end
      end

      context 'with deploy freeze period `if:` clause' do
        # '0 23 * * 5' == "At 23:00 on Friday."", '0 7 * * 1' == "At 07:00 on Monday.""
        let!(:freeze_period) { create(:ci_freeze_period, project: project, freeze_start: '0 23 * * 5', freeze_end: '0 7 * * 1') }

        context 'with 2 jobs' do
          let(:config) do
            <<-EOY
            stages:
              - test
              - deploy

            test-job:
              script:
                - echo 'running TEST stage'

            deploy-job:
              stage: deploy
              script:
                - echo 'running DEPLOY stage'
              rules:
                - if: $CI_DEPLOY_FREEZE == null
            EOY
          end

          context 'when outside freeze period' do
            it 'creates two jobs' do
              Timecop.freeze(2020, 4, 10, 22, 59) do
                expect(pipeline).to be_persisted
                expect(build_names).to contain_exactly('test-job', 'deploy-job')
              end
            end
          end

          context 'when inside freeze period' do
            it 'creates one job' do
              Timecop.freeze(2020, 4, 10, 23, 1) do
                expect(pipeline).to be_persisted
                expect(build_names).to contain_exactly('test-job')
              end
            end
          end
        end

        context 'with 1 job' do
          let(:config) do
            <<-EOY
            stages:
              - deploy

            deploy-job:
              stage: deploy
              script:
                - echo 'running DEPLOY stage'
              rules:
                - if: $CI_DEPLOY_FREEZE == null
            EOY
          end

          context 'when outside freeze period' do
            it 'creates two jobs' do
              Timecop.freeze(2020, 4, 10, 22, 59) do
                expect(pipeline).to be_persisted
                expect(build_names).to contain_exactly('deploy-job')
              end
            end
          end

          context 'when inside freeze period' do
            it 'does not create the pipeline' do
              Timecop.freeze(2020, 4, 10, 23, 1) do
                expect(pipeline).not_to be_persisted
              end
            end
          end
        end
      end

      context 'with workflow rules with persisted variables' do
        let(:config) do
          <<-EOY
            workflow:
              rules:
                - if: $CI_COMMIT_REF_NAME == "master"

            regular-job:
              script: 'echo Hello, World!'
          EOY
        end

        context 'with matches' do
          it 'creates a pipeline' do
            expect(pipeline).to be_persisted
            expect(build_names).to contain_exactly('regular-job')
          end
        end

        context 'with no matches' do
          let(:ref_name) { 'refs/heads/feature' }

          it 'does not create a pipeline' do
            expect(pipeline).not_to be_persisted
          end
        end
      end

      context 'with workflow rules with pipeline variables' do
        let(:pipeline) do
          execute_service(variables_attributes: variables_attributes)
        end

        let(:config) do
          <<-EOY
            workflow:
              rules:
                - if: $SOME_VARIABLE

            regular-job:
              script: 'echo Hello, World!'
          EOY
        end

        context 'with matches' do
          let(:variables_attributes) do
            [{ key: 'SOME_VARIABLE', secret_value: 'SOME_VAR' }]
          end

          it 'creates a pipeline' do
            expect(pipeline).to be_persisted
            expect(build_names).to contain_exactly('regular-job')
          end
        end

        context 'with no matches' do
          let(:variables_attributes) { {} }

          it 'does not create a pipeline' do
            expect(pipeline).not_to be_persisted
          end
        end
      end

      context 'with workflow rules with trigger variables' do
        let(:pipeline) do
          execute_service do |pipeline|
            pipeline.variables.build(variables)
          end
        end

        let(:config) do
          <<-EOY
            workflow:
              rules:
                - if: $SOME_VARIABLE

            regular-job:
              script: 'echo Hello, World!'
          EOY
        end

        context 'with matches' do
          let(:variables) do
            [{ key: 'SOME_VARIABLE', secret_value: 'SOME_VAR' }]
          end

          it 'creates a pipeline' do
            expect(pipeline).to be_persisted
            expect(build_names).to contain_exactly('regular-job')
          end

          context 'when a job requires the same variable' do
            let(:config) do
              <<-EOY
                workflow:
                  rules:
                    - if: $SOME_VARIABLE

                build:
                  stage: build
                  script: 'echo build'
                  rules:
                    - if: $SOME_VARIABLE

                test1:
                  stage: test
                  script: 'echo test1'
                  needs: [build]

                test2:
                  stage: test
                  script: 'echo test2'
              EOY
            end

            it 'creates a pipeline' do
              expect(pipeline).to be_persisted
              expect(build_names).to contain_exactly('build', 'test1', 'test2')
            end
          end
        end

        context 'with no matches' do
          let(:variables) { {} }

          it 'does not create a pipeline' do
            expect(pipeline).not_to be_persisted
          end

          context 'when a job requires the same variable' do
            let(:config) do
              <<-EOY
                workflow:
                  rules:
                    - if: $SOME_VARIABLE

                build:
                  stage: build
                  script: 'echo build'
                  rules:
                    - if: $SOME_VARIABLE

                test1:
                  stage: test
                  script: 'echo test1'
                  needs: [build]

                test2:
                  stage: test
                  script: 'echo test2'
              EOY
            end

            it 'does not create a pipeline' do
              expect(pipeline).not_to be_persisted
            end
          end
        end
      end
    end
  end

  describe '#execute!' do
    subject { service.execute!(*args) }

    let(:service) { described_class.new(project, user, ref: ref_name) }
    let(:args) { [:push] }

    context 'when user has a permission to create a pipeline' do
      let(:user) { create(:user) }

      before do
        project.add_developer(user)
      end

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end

      it 'creates a pipeline' do
        expect { subject }.to change { Ci::Pipeline.count }.by(1)
      end
    end

    context 'when user does not have a permission to create a pipeline' do
      let(:user) { create(:user) }

      it 'raises an error' do
        expect { subject }
          .to raise_error(described_class::CreateError)
          .with_message('Insufficient permissions to create a new pipeline')
      end
    end

    context 'when a user with permissions has been blocked' do
      before do
        user.block!
      end

      it 'raises an error' do
        expect { subject }
          .to raise_error(described_class::CreateError)
          .with_message('Insufficient permissions to create a new pipeline')
      end
    end
  end
end
