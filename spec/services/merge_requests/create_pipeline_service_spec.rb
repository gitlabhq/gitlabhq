# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::CreatePipelineService, :clean_gitlab_redis_cache, feature_category: :code_review_workflow do
  include ProjectForksHelper

  let_it_be(:project, refind: true) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:service) { described_class.new(project: project, current_user: actor, params: params) }
  let(:actor) { user }
  let(:params) { {} }

  before do
    project.add_developer(user)
  end

  describe '#execute' do
    subject(:response) { service.execute(merge_request) }

    before do
      stub_ci_pipeline_yaml_file(YAML.dump(config))
    end

    let(:config) do
      { rspec: { script: 'echo', only: ['merge_requests'] } }
    end

    let(:merge_request) do
      create(:merge_request,
        source_branch: 'feature',
        source_project: source_project,
        target_branch: 'master',
        target_project: project)
    end

    let(:source_project) { project }

    it 'creates a detached merge request pipeline' do
      expect { response }.to change { Ci::Pipeline.count }.by(1)

      expect(response).to be_success
      expect(response.payload).to be_persisted
      expect(response.payload).to be_detached_merge_request_pipeline
    end

    it 'defaults to merge_request_event' do
      expect(response.payload.source).to eq('merge_request_event')
    end

    context 'when push options contain ci.skip' do
      let(:params) { { push_options: { ci: { skip: true } } } }

      it 'creates a skipped pipeline' do
        expect { response }.to change { Ci::Pipeline.count }.by(1)

        expect(response).to be_success
        expect(response.payload).to be_persisted
        expect(response.payload.builds).to be_empty
        expect(response.payload).to be_skipped
      end
    end

    context 'with fork merge request' do
      let_it_be(:forked_project) { fork_project(project, nil, repository: true, target_project: create(:project, :private, :repository)) }

      let(:source_project) { forked_project }

      context 'when actor has permission to create pipelines in target project' do
        let(:actor) { user }

        it 'creates a pipeline in the target project' do
          expect(response.payload.project).to eq(project)
        end

        context 'when the feature is disabled in CI/CD settings' do
          before do
            project.update!(ci_allow_fork_pipelines_to_run_in_parent_project: false)
          end

          it 'creates a pipeline in the source project' do
            expect(response.payload.project).to eq(source_project)
          end
        end

        context 'when source branch is protected' do
          context 'when actor does not have permission to update the protected branch in target project' do
            let!(:protected_branch) { create(:protected_branch, name: '*', project: project) }

            it 'creates a pipeline in the source project' do
              expect(response.payload.project).to eq(source_project)
            end
          end

          context 'when actor has permission to update the protected branch in target project' do
            let!(:protected_branch) { create(:protected_branch, :developers_can_merge, name: '*', project: project) }

            it 'creates a pipeline in the target project' do
              expect(response.payload.project).to eq(project)
            end
          end
        end
      end

      context 'when actor has permission to create pipelines in forked project' do
        let(:actor) { fork_user }
        let(:fork_user) { create(:user) }

        before do
          source_project.add_developer(fork_user)
        end

        it 'creates a pipeline in the source project' do
          expect(response.payload.project).to eq(source_project)
        end
      end

      context 'when actor does not have permission to create pipelines' do
        let(:actor) { create(:user) }

        it 'responds with error' do
          expect(response).to be_error
          expect(response.message).to include('Insufficient permissions to create a new pipeline')
        end
      end
    end

    context 'when service is called multiple times' do
      it 'creates a pipeline once' do
        expect do
          service.execute(merge_request)
          service.execute(merge_request)
        end.to change { Ci::Pipeline.count }.by(1)
      end

      context 'when allow_duplicate option is true' do
        let(:params) { { allow_duplicate: true } }

        it 'creates pipelines multiple times' do
          expect do
            service.execute(merge_request)
            service.execute(merge_request)
          end.to change { Ci::Pipeline.count }.by(2)
        end
      end
    end

    context 'when .gitlab-ci.yml does not use workflow:rules' do
      context 'without only: [merge_requests] keyword' do
        let(:config) do
          { rspec: { script: 'echo' } }
        end

        it 'does not create a pipeline' do
          expect { response }.not_to change { Ci::Pipeline.count }
        end
      end

      context 'with rules that specify creation on a tag' do
        let(:config) do
          {
            rspec: {
              script: 'echo',
              rules: [{ if: '$CI_COMMIT_TAG' }]
            }
          }
        end

        it 'does not create a pipeline' do
          expect { response }.not_to change { Ci::Pipeline.count }
        end
      end
    end

    context 'when workflow:rules are specified' do
      context 'when rules request creation on merge request' do
        let(:config) do
          {
            workflow: {
              rules: [{ if: '$CI_MERGE_REQUEST_ID' }]
            },
            rspec: { script: 'echo' }
          }
        end

        it 'creates a detached merge request pipeline', :aggregate_failures do
          expect { response }.to change { Ci::Pipeline.count }.by(1)

          expect(response).to be_success
          expect(response.payload).to be_persisted
          expect(response.payload).to be_detached_merge_request_pipeline
        end
      end

      context 'with rules do specify creation on a tag' do
        let(:config) do
          {
            workflow: {
              rules: [{ if: '$CI_COMMIT_TAG' }]
            },
            rspec: { script: 'echo' }
          }
        end

        it 'does not create a pipeline', :aggregate_failures do
          expect { response }.not_to change { Ci::Pipeline.count }
          expect(response).to be_error
        end
      end
    end

    context 'when merge request has no commits' do
      before do
        allow(merge_request).to receive(:has_no_commits?).and_return(true)
      end

      it 'does not create a pipeline', :aggregate_failures do
        expect { response }.not_to change { Ci::Pipeline.count }

        expect(response).to be_error
        expect(response.message).to eq('Cannot create a pipeline for this merge request.')
        expect(response.payload).to be_nil
      end
    end

    context 'when merge request pipeline creates a dynamic environment' do
      let(:config) do
        {
          review_app: {
            script: 'echo',
            only: ['merge_requests'],
            environment: { name: "review/$CI_COMMIT_REF_NAME" }
          }
        }
      end

      it 'associates merge request with the environment' do
        expect { response }.to change { Ci::Pipeline.count }.by(1)

        environment = Environment.find_by_name('review/feature')
        expect(response).to be_success
        expect(environment).to be_present
        expect(environment.merge_request).to eq(merge_request)
      end
    end
  end
end
