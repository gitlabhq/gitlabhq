# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Refresh::PipelineService, :sidekiq_inline, feature_category: :code_review_workflow do
  include ProjectForksHelper

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:project_fork) { fork_project(project, user, repository: true) }
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let_it_be(:another_merge_request) do
    create(
      :merge_request,
      source_project: project,
      source_branch: 'master',
      target_branch: 'test',
      target_project: project
    )
  end

  let_it_be(:fork_merge_request) do
    create(
      :merge_request,
      source_project: project_fork,
      source_branch: 'master',
      target_branch: 'feature',
      target_project: project
    )
  end

  let(:service) { described_class.new(project: project, current_user: user) }
  let(:oldrev) { 'old_sha' }
  let(:newrev) { 'new_sha' }
  let(:ref) { 'refs/heads/master' }

  before_all do
    project.add_developer(user)
  end

  describe '#execute' do
    subject(:execute) { service.execute(oldrev, newrev, ref) }

    context 'when branch is removed' do
      before do
        allow_next_instance_of(Gitlab::Git::Push) do |push|
          allow(push).to receive(:branch_removed?).and_return(true)
        end
      end

      it 'does not refresh pipelines' do
        expect(service).not_to receive(:refresh_pipelines)
        execute
      end
    end

    context 'when branch is not removed' do
      let(:config) do
        YAML.dump({
          test: {
            stage: 'test',
            script: 'echo',
            only: ['merge_requests']
          }
        })
      end

      before do
        stub_ci_pipeline_yaml_file(config)
      end

      context "when .gitlab-ci.yml has merge_requests keywords" do
        it 'create detached merge request pipeline with commits' do
          expect { execute }
            .to change { merge_request.pipelines_for_merge_request.count }.by(1)
            .and not_change { another_merge_request.pipelines_for_merge_request.count }

          expect(merge_request.has_commits?).to be_truthy
          expect(another_merge_request.has_commits?).to be_falsy
        end

        context 'when "push_options: nil" is passed' do
          let(:service_instance) do
            described_class.new(project: project, current_user: user, params: { push_options: nil })
          end

          subject(:execute) { service_instance.execute(oldrev, newrev, ref) }

          it 'creates a detached merge request pipeline with commits' do
            expect { execute }
              .to change { merge_request.pipelines_for_merge_request.count }.by(1)
              .and not_change { another_merge_request.pipelines_for_merge_request.count }

            expect(merge_request.has_commits?).to be_truthy
            expect(another_merge_request.has_commits?).to be_falsy
          end
        end

        context 'when ci.skip push_options are passed' do
          let(:params) { { push_options: { ci: { skip: true } } } }
          let(:service_instance) { described_class.new(project: project, current_user: user, params: params) }

          subject(:execute) { service_instance.execute(oldrev, newrev, ref) }

          it 'creates a skipped detached merge request pipeline with commits' do
            expect { execute }
              .to change { merge_request.pipelines_for_merge_request.count }.by(1)
              .and not_change { another_merge_request.pipelines_for_merge_request.count }

            expect(merge_request.has_commits?).to be_truthy
            expect(another_merge_request.has_commits?).to be_falsy

            pipeline = merge_request.pipelines_for_merge_request.last
            expect(pipeline).to be_skipped
          end
        end

        it 'does not create detached merge request pipeline for forked project' do
          expect { execute }
            .not_to change { fork_merge_request.pipelines_for_merge_request.count }
        end

        it 'create detached merge request pipeline for non-fork merge request' do
          execute

          expect(merge_request.pipelines_for_merge_request.first)
            .to be_detached_merge_request_pipeline
        end

        context 'when service is hooked by target branch' do
          let(:ref) { 'refs/heads/feature' }

          it 'does not create detached merge request pipeline' do
            expect { execute }
              .not_to change { merge_request.pipelines_for_merge_request.count }
          end
        end

        context 'when service runs on forked project' do
          subject(:execute) do
            described_class.new(project: project_fork, current_user: user).execute(oldrev, newrev, ref)
          end

          it 'creates detached merge request pipeline for fork merge request' do
            expect { execute }
              .to change { fork_merge_request.pipelines_for_merge_request.count }.by(1)

            merge_request_pipeline = fork_merge_request.pipelines_for_merge_request.first
            expect(merge_request_pipeline).to be_detached_merge_request_pipeline
            expect(merge_request_pipeline.project).to eq(project)
          end
        end

        context "when branch pipeline was created before a detached merge request pipeline has been created" do
          before do
            create(
              :ci_pipeline,
              project: merge_request.source_project,
              sha: merge_request.diff_head_sha,
              ref: merge_request.source_branch,
              tag: false
            )

            execute
          end

          it 'sets the latest detached merge request pipeline as a head pipeline' do
            merge_request.reload
            expect(merge_request.diff_head_pipeline).to be_merge_request_event
          end

          it 'returns pipelines in correct order' do
            merge_request.reload
            expect(merge_request.all_pipelines.first).to be_merge_request_event
            expect(merge_request.all_pipelines.second).to be_push
          end
        end

        context "when the service is run twice" do
          it 'does not re-create a duplicate detached merge request pipeline' do
            expect do
              described_class.new(project: project, current_user: user).execute(oldrev, newrev, 'refs/heads/master')
            end.to change { merge_request.pipelines_for_merge_request.count }.by(1)

            expect do
              described_class.new(project: project, current_user: user).execute(oldrev, newrev, 'refs/heads/master')
            end.not_to change { merge_request.pipelines_for_merge_request.count }
          end
        end
      end

      context "when .gitlab-ci.yml does not have merge_requests keywords" do
        let(:config) do
          YAML.dump({
            test: {
              stage: 'test',
              script: 'echo'
            }
          })
        end

        it 'does not create a detached merge request pipeline' do
          expect { execute }
            .not_to change { merge_request.pipelines_for_merge_request.count }
        end
      end

      context 'when .gitlab-ci.yml is invalid' do
        let(:config) { 'invalid yaml file' }

        it 'persists a pipeline with config error' do
          expect { execute }
            .to change { merge_request.pipelines_for_merge_request.count }.by(1)
          expect(merge_request.pipelines_for_merge_request.last).to be_failed
          expect(merge_request.pipelines_for_merge_request.last).to be_config_error
        end
      end

      context 'when .gitlab-ci.yml file is valid but has a logical error' do
        let(:config) do
          YAML.dump({
            build: {
              script: 'echo "Valid yaml syntax, but..."',
              only: ['master']
            },
            test: {
              script: 'echo "... I depend on build, which does not run."',
              only: ['merge_request'],
              needs: ['build']
            }
          })
        end

        it 'persists a pipeline with config error' do
          expect { execute }
            .to change { merge_request.pipelines_for_merge_request.count }.by(1)
          expect(merge_request.pipelines_for_merge_request.last).to be_failed
          expect(merge_request.pipelines_for_merge_request.last).to be_config_error
        end
      end
    end
  end
end
