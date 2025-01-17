# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::CommitStatuses, :clean_gitlab_redis_cache, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:commit) { project.repository.commit }
  let_it_be(:guest) { create_user(:guest) }
  let_it_be(:reporter) { create_user(:reporter) }
  let_it_be(:developer) { create_user(:developer) }
  let_it_be(:sha) { commit.id }

  describe "GET /projects/:id/repository/commits/:sha/statuses" do
    let(:get_url) { "/projects/#{project.id}/repository/commits/#{sha}/statuses" }

    context 'ci commit exists' do
      let!(:master) do
        project.ci_pipelines.build(source: :push, sha: commit.id, ref: 'master', protected: false).tap do |p|
          p.ensure_project_iid! # Necessary to avoid cross-database modification error
          p.save!
        end
      end

      let!(:develop) do
        project.ci_pipelines.build(source: :push, sha: commit.id, ref: 'develop', protected: false).tap do |p|
          p.ensure_project_iid! # Necessary to avoid cross-database modification error
          p.save!
        end
      end

      context "reporter user" do
        let(:statuses_id) { json_response.map { |status| status['id'] } }

        def create_status(pipeline, opts = {})
          create(:commit_status, { pipeline: pipeline, ref: pipeline.ref }.merge(opts))
        end

        let!(:status1) { create_status(master, status: 'running', retried: true) }
        let!(:status2) { create_status(master, name: 'coverage', status: 'pending', retried: true) }
        let!(:status3) { create_status(develop, status: 'running', allow_failure: true) }
        let!(:status4) { create_status(master, name: 'coverage', status: 'success') }
        let!(:status5) { create_status(develop, name: 'coverage', status: 'success') }
        let!(:status6) { create_status(master, status: 'success', stage: 'deploy') }

        context 'latest commit statuses' do
          before do
            get api(get_url, reporter)
          end

          it 'returns latest commit statuses' do
            expect(response).to have_gitlab_http_status(:ok)

            expect(response).to include_pagination_headers
            expect(json_response).to be_an Array
            expect(statuses_id).to contain_exactly(status3.id, status4.id, status5.id, status6.id)
            json_response.sort_by! { |status| status['id'] }
            expect(json_response.map { |status| status['allow_failure'] }).to eq([true, false, false, false])
          end
        end

        shared_examples_for 'get commit statuses' do
          before do
            get api(get_url, reporter), params: params
          end

          it 'returns all commit statuses' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(json_response).to be_an Array
            expect(statuses_id).to eq(expected_statuses)
          end
        end

        context 'Get all commit statuses' do
          let(:params) { { all: 1 } }
          let(:expected_statuses) { [status1.id, status2.id, status3.id, status4.id, status5.id, status6.id] }

          it_behaves_like 'get commit statuses'
        end

        context 'commit statuses filtered by stage' do
          before do
            get api(get_url, reporter), params: { stage: 'deploy' }
          end

          it 'returns all commit statuses with the specified stage' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(json_response).to be_an Array
            expect(statuses_id).to contain_exactly(status6.id)
          end
        end

        context 'latest commit statuses for specific ref' do
          let(:params) { { ref: 'develop' } }
          let(:expected_statuses) { [status3.id, status5.id] }

          it_behaves_like 'get commit statuses'
        end

        context 'latest commit statues for specific name' do
          let(:params) { { name: 'coverage' } }
          let(:expected_statuses) { [status4.id, status5.id] }

          it_behaves_like 'get commit statuses'
        end

        context 'latest commit statuses for specific pipeline' do
          let(:params) { { pipeline_id: develop.id } }
          let(:expected_statuses) { [status3.id, status5.id] }

          it_behaves_like 'get commit statuses'
        end

        context 'return commit statuses sort by desc id' do
          let(:params) { { all: 1, sort: "desc" } }
          let(:expected_statuses) { [status6.id, status5.id, status4.id, status3.id, status2.id, status1.id] }

          it_behaves_like 'get commit statuses'
        end

        context 'return commit statuses sort by desc pipeline_id' do
          let(:params) { { all: 1, order_by: "pipeline_id", sort: "desc" } }
          let(:expected_statuses) { [status3.id, status5.id, status1.id, status2.id, status4.id, status6.id] }

          it_behaves_like 'get commit statuses'
        end

        context 'return commit statuses sort by asc pipeline_id' do
          let(:params) { { all: 1, order_by: "pipeline_id" } }
          let(:expected_statuses) { [status1.id, status2.id, status4.id, status6.id, status3.id, status5.id] }

          it_behaves_like 'get commit statuses'
        end

        context 'Bad filter commit statuses' do
          it 'return commit statuses order by an unmanaged field' do
            get api(get_url, reporter), params: { all: 1, order_by: "name" }

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end
    end

    context 'ci commit does not exist' do
      before do
        get api(get_url, reporter)
      end

      it 'returns empty array' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response).to be_empty
      end
    end

    context "guest user" do
      before do
        get api(get_url, guest)
      end

      it "does not return project commits" do
        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to eq('403 Forbidden')
      end
    end

    context "unauthorized user" do
      before do
        get api(get_url)
      end

      it "does not return project commits" do
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /projects/:id/statuses/:sha' do
    let(:post_url) { "/projects/#{project.id}/statuses/#{sha}" }

    context 'developer user' do
      context 'uses only required parameters' do
        valid_statues = %w[pending running success failed canceled skipped]
        valid_statues.each do |status|
          context "for #{status}" do
            context 'when pipeline for sha does not exists' do
              it 'creates commit status and sets pipeline iid' do
                post api(post_url, developer), params: { state: status }

                expect(response).to have_gitlab_http_status(:created)
                expect(json_response['sha']).to eq(commit.id)
                expect(json_response['status']).to eq(status)
                expect(json_response['name']).to eq('default')
                expect(json_response['ref']).not_to be_empty
                expect(json_response['target_url']).to be_nil
                expect(json_response['description']).to be_nil
                expect(json_response['pipeline_id']).not_to be_nil

                if status == 'failed'
                  expect(CommitStatus.find(json_response['id'])).to be_api_failure
                end

                expect(::Ci::Pipeline.last.iid).not_to be_nil
              end
            end
          end
        end

        context 'when pipeline already exists for the specified sha' do
          let!(:pipeline) { create(:ci_pipeline, project: project, sha: sha, ref: 'ref') }
          let(:params) { { state: 'pending' } }

          shared_examples_for 'creates a commit status for the existing pipeline with an external stage' do
            it do
              expect do
                post api(post_url, developer), params: params
              end.not_to change { Ci::Pipeline.count }

              job = pipeline.statuses.find_by_name(json_response['name'])

              expect(response).to have_gitlab_http_status(:created)
              expect(job.ci_stage.name).to eq('external')
              expect(job.ci_stage.position).to eq(GenericCommitStatus::EXTERNAL_STAGE_IDX)
              expect(job.ci_stage.pipeline).to eq(pipeline)
              expect(job.status).to eq('pending')
              expect(job.stage_idx).to eq(GenericCommitStatus::EXTERNAL_STAGE_IDX)
            end
          end

          shared_examples_for 'updates the commit status with an external stage' do
            before do
              post api(post_url, developer), params: { state: 'pending' }
            end

            it 'updates the commit status with the external stage' do
              post api(post_url, developer), params: { state: 'running' }
              job = pipeline.statuses.find_by_name(json_response['name'])

              expect(job.ci_stage.name).to eq('external')
              expect(job.ci_stage.position).to eq(GenericCommitStatus::EXTERNAL_STAGE_IDX)
              expect(job.ci_stage.pipeline).to eq(pipeline)
              expect(job.status).to eq('running')
              expect(job.stage_idx).to eq(GenericCommitStatus::EXTERNAL_STAGE_IDX)
            end
          end

          context 'with pipeline for merge request' do
            let!(:merge_request) { create(:merge_request, :with_detached_merge_request_pipeline, source_project: project) }
            let!(:pipeline) { merge_request.all_pipelines.last }
            let(:sha) { pipeline.sha }

            it_behaves_like 'creates a commit status for the existing pipeline with an external stage'
          end

          context 'when an external stage does not exist' do
            context 'when the commit status does not exist' do
              it_behaves_like 'creates a commit status for the existing pipeline with an external stage'
            end

            context 'when the commit status exists' do
              it_behaves_like 'updates the commit status with an external stage'
            end
          end

          context 'when an external stage already exists' do
            let(:stage) { create(:ci_stage, name: 'external', pipeline: pipeline, position: 1_000_000) }

            context 'when the commit status exists' do
              it_behaves_like 'updates the commit status with an external stage'
            end

            context 'when the commit status does not exist' do
              it_behaves_like 'creates a commit status for the existing pipeline with an external stage'
            end
          end
        end

        context 'when the pipeline does not exist' do
          it 'creates a commit status and a stage' do
            expect do
              post api(post_url, developer), params: { state: 'pending' }
            end.to change { Ci::Pipeline.count }.by(1)
            job = Ci::Pipeline.last.statuses.find_by_name(json_response['name'])

            expect(job.ci_stage.name).to eq('external')
            expect(job.ci_stage.position).to eq(GenericCommitStatus::EXTERNAL_STAGE_IDX)
            expect(job.status).to eq('pending')
            expect(job.stage_idx).to eq(GenericCommitStatus::EXTERNAL_STAGE_IDX)
          end
        end
      end

      context 'when status transitions from pending' do
        before do
          post api(post_url, developer), params: { state: 'pending' }
        end

        valid_statues = %w[running success failed canceled]
        valid_statues.each do |status|
          it "to #{status}" do
            expect { post api(post_url, developer), params: { state: status } }.not_to change { CommitStatus.count }

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['status']).to eq(status)
          end
        end
      end

      context 'with all optional parameters' do
        context 'when creating a commit status' do
          subject do
            post api(post_url, developer), params: {
              state: 'success',
              context: 'coverage',
              ref: 'master',
              description: 'test',
              coverage: 80.0,
              target_url: 'http://gitlab.com/status'
            }
          end

          it 'creates commit status' do
            subject

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['sha']).to eq(commit.id)
            expect(json_response['status']).to eq('success')
            expect(json_response['name']).to eq('coverage')
            expect(json_response['ref']).to eq('master')
            expect(json_response['coverage']).to eq(80.0)
            expect(json_response['description']).to eq('test')
            expect(json_response['target_url']).to eq('http://gitlab.com/status')
          end

          context 'when merge request exists for given branch' do
            let!(:merge_request) do
              create(:merge_request, source_project: project, head_pipeline_id: nil)
            end

            it 'sets head pipeline', :sidekiq_inline do
              subject

              expect(response).to have_gitlab_http_status(:created)
              expect(merge_request.reload.head_pipeline).not_to be_nil
            end
          end
        end

        context 'when updating a commit status' do
          let(:parameters) do
            {
              state: 'success',
              name: 'coverage',
              ref: 'master'
            }
          end

          let(:updatable_optional_attributes) do
            {
              description: 'new description',
              coverage: 90.0
            }
          end

          # creating the initial commit status
          before do
            post api(post_url, developer), params: {
              state: 'running',
              context: 'coverage',
              ref: 'master',
              description: 'coverage test',
              coverage: 10.0,
              target_url: 'http://gitlab.com/status'
            }
          end

          subject(:send_request) do
            post api(post_url, developer), params: {
              **parameters,
              **updatable_optional_attributes
            }
          end

          it 'updates a commit status' do
            send_request

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['sha']).to eq(commit.id)
            expect(json_response['status']).to eq('success')
            expect(json_response['name']).to eq('coverage')
            expect(json_response['ref']).to eq('master')
            expect(json_response['coverage']).to eq(90.0)
            expect(json_response['description']).to eq('new description')
            expect(json_response['target_url']).to eq('http://gitlab.com/status')
          end

          it 'does not create a new commit status' do
            expect { send_request }.not_to change { CommitStatus.count }
          end

          context 'when the `state` parameter is sent the same' do
            let(:parameters) do
              {
                state: 'running',
                name: 'coverage',
                ref: 'master'
              }
            end

            it 'does not update the commit status' do
              send_request

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(json_response['message']).to eq("Cannot transition status via :run from :running (Reason(s): Status cannot transition via \"run\")")

              commit_status = project.commit_statuses.find_by!(name: 'coverage')

              expect(commit_status.description).to eq('coverage test')
              expect(commit_status.coverage).to eq(10.0)
            end
          end
        end

        context 'when a pipeline id is specified' do
          let!(:first_pipeline) do
            project.ci_pipelines.build(source: :push, sha: commit.id, ref: 'master', status: 'created').tap do |p|
              p.ensure_project_iid! # Necessary to avoid cross-database modification error
              p.save!
            end
          end

          let!(:other_pipeline) do
            project.ci_pipelines.build(source: :push, sha: commit.id, ref: 'master', status: 'created').tap do |p|
              p.ensure_project_iid! # Necessary to avoid cross-database modification error
              p.save!
            end
          end

          subject do
            post api(post_url, developer), params: {
              pipeline_id: other_pipeline.id,
              state: 'success',
              ref: 'master'
            }
          end

          it 'update the correct pipeline', :sidekiq_might_not_need_inline do
            subject

            expect(first_pipeline.reload.status).to eq('created')
            expect(other_pipeline.reload.status).to eq('success')
          end
        end
      end

      context 'when retrying a commit status' do
        subject(:post_request) do
          post api(post_url, developer),
            params: { state: 'failed', name: 'test', ref: 'master' }

          post api(post_url, developer),
            params: { state: 'success', name: 'test', ref: 'master' }
        end

        it 'correctly posts a new commit status' do
          post_request

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['sha']).to eq(commit.id)
          expect(json_response['status']).to eq('success')
        end

        it 'retries the commit status', :sidekiq_might_not_need_inline do
          post_request

          expect(CommitStatus.count).to eq 2
          expect(CommitStatus.first).to be_retried
          expect(CommitStatus.last.pipeline).to be_success
        end
      end

      context 'when status is invalid' do
        before do
          post api(post_url, developer), params: { state: 'invalid' }
        end

        it 'does not create commit status' do
          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq(nil)
        end
      end

      context 'when request without a state made' do
        before do
          post api(post_url, developer)
        end

        it 'does not create commit status' do
          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq(nil)
        end
      end

      context 'when updating a protected ref' do
        before do
          create(:protected_branch, project: project, name: 'master')
          post api(post_url, user), params: { state: 'running', ref: 'master' }
        end

        context 'with user as developer' do
          let(:user) { developer }

          it 'does not create commit status' do
            expect(response).to have_gitlab_http_status(:forbidden)
            expect(json_response['message']).to eq('403 Forbidden')
          end
        end

        context 'with user as maintainer' do
          let(:user) { create_user(:maintainer) }

          it 'creates commit status' do
            expect(response).to have_gitlab_http_status(:created)
          end
        end
      end

      context 'when commit SHA is invalid' do
        let(:sha) { 'invalid_sha' }

        before do
          post api(post_url, developer), params: { state: 'running' }
        end

        it 'returns not found error' do
          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('404 Commit Not Found')
        end
      end

      context 'when target URL is an invalid address' do
        before do
          post api(post_url, developer), params: {
                                          state: 'pending',
                                          target_url: 'invalid url'
                                        }
        end

        it 'responds with bad request status and validation errors' do
          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']['target_url'])
            .to include 'is blocked: Only allowed schemes are http, https'
        end
      end

      context 'when target URL is an unsupported scheme' do
        before do
          post api(post_url, developer), params: {
                                          state: 'pending',
                                          target_url: 'git://example.com'
                                        }
        end

        it 'responds with bad request status and validation errors' do
          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']['target_url'])
              .to include 'is blocked: Only allowed schemes are http, https'
        end
      end

      context 'when trying to update a status of a different type' do
        let!(:pipeline) { create(:ci_pipeline, project: project, sha: sha, ref: 'ref') }
        let!(:ci_build) { create(:ci_build, pipeline: pipeline, name: 'test-job') }
        let(:params) { { state: 'pending', name: 'test-job' } }

        before do
          post api(post_url, developer), params: params
        end

        it 'responds with bad request status and validation errors' do
          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']['name'])
              .to include 'has already been taken'
        end
      end

      context 'with partitions' do
        include Ci::PartitioningHelpers

        let(:current_partition_id) { ci_testing_partition_id }

        before do
          stub_current_partition_id(ci_testing_partition_id)
        end

        it 'creates records in the current partition' do
          expect { post api(post_url, developer), params: { state: 'running' } }
            .to change(CommitStatus, :count).by(1)
            .and change(Ci::Pipeline, :count).by(1)

          status = CommitStatus.find(json_response['id'])

          expect(status.partition_id).to eq(current_partition_id)
          expect(status.pipeline.partition_id).to eq(current_partition_id)
        end
      end
    end

    context 'reporter user' do
      before do
        post api(post_url, reporter), params: { state: 'running' }
      end

      it 'does not create commit status' do
        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to eq('403 Forbidden')
      end
    end

    context 'guest user' do
      before do
        post api(post_url, guest), params: { state: 'running' }
      end

      it 'does not create commit status' do
        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to eq('403 Forbidden')
      end
    end

    context 'unauthorized user' do
      before do
        post api(post_url)
      end

      it 'does not create commit status' do
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  def create_user(access_level_trait)
    user = create(:user)
    create(:project_member, access_level_trait, user: user, project: project)
    user
  end
end
