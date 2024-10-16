# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreateCommitStatusService, :clean_gitlab_redis_cache, feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax

  subject(:response) { execute_service(params) }

  let_it_be_with_refind(:project) { create(:project, :repository) }
  let_it_be(:commit) { project.repository.commit }
  let_it_be(:guest) { create_user(:guest) }
  let_it_be(:reporter) { create_user(:reporter) }
  let_it_be(:developer) { create_user(:developer) }

  let(:user) { developer }
  let(:sha) { commit.id }
  let(:params) { { state: 'pending' } }
  let(:job) { response.payload[:job] }

  %w[pending running success failed canceled skipped].each do |status|
    context "for #{status}" do
      let(:params) { { state: status } }

      context 'when pipeline for sha does not exists' do
        it 'creates commit status and sets pipeline iid' do
          expect(response).to be_success
          expect(job.sha).to eq(commit.id)
          expect(job.status).to eq(status)
          expect(job.name).to eq('default')
          expect(job.ref).not_to be_empty
          expect(job.target_url).to be_nil
          expect(job.description).to be_nil
          expect(job.pipeline_id).not_to be_nil

          expect(CommitStatus.find(job.id)).to be_api_failure if status == 'failed'

          expect(::Ci::Pipeline.last.iid).not_to be_nil
        end
      end
    end
  end

  context 'when status transitions from pending' do
    before do
      execute_service(state: 'pending')
    end

    %w[running success failed canceled skipped].each do |status|
      context "for #{status}" do
        let(:params) { { state: status } }

        it "changes to #{status}" do
          expect { response }
            .to not_change { ::Ci::Pipeline.count }.from(1)
            .and not_change { ::Ci::Stage.count }.from(1)
            .and not_change { ::CommitStatus.count }.from(1)

          expect(response).to be_success
          expect(job.status).to eq(status)
        end
      end
    end

    context 'for invalid transition' do
      let(:params) { { state: 'pending' } }

      it 'returns bad request and error message' do
        expect { response }
          .to not_change { ::Ci::Pipeline.count }.from(1)
          .and not_change { ::Ci::Stage.count }.from(1)
          .and not_change { ::CommitStatus.count }.from(1)

        expect(response).to be_error
        expect(response.http_status).to eq(:bad_request)
        expect(response.message).to eq(
          "Cannot transition status via :enqueue from :pending (Reason(s): Status cannot transition via \"enqueue\")"
        )
      end
    end
  end

  context 'with all optional parameters' do
    context 'when creating a commit status' do
      let(:params) do
        {
          sha: sha,
          state: 'success',
          context: 'coverage',
          ref: 'master',
          description: 'test',
          coverage: 80.0,
          target_url: 'http://gitlab.com/status'
        }
      end

      it 'creates commit status' do
        expect { response }
          .to change { ::Ci::Pipeline.count }.by(1)
          .and change { ::Ci::Stage.count }.by(1)
          .and change { ::CommitStatus.count }.by(1)

        expect(response).to be_success
        expect(job.sha).to eq(commit.id)
        expect(job.status).to eq('success')
        expect(job.name).to eq('coverage')
        expect(job.ref).to eq('master')
        expect(job.coverage).to eq(80.0)
        expect(job.description).to eq('test')
        expect(job.target_url).to eq('http://gitlab.com/status')
      end

      context 'when merge request exists for given branch' do
        let!(:merge_request) do
          create(:merge_request, source_project: project, head_pipeline: nil)
        end

        it 'sets head pipeline', :sidekiq_inline do
          expect { response }
            .to change { ::Ci::Pipeline.count }.by(1)
            .and change { ::Ci::Stage.count }.by(1)
            .and change { ::CommitStatus.count }.by(1)

          expect(response).to be_success
          expect(merge_request.reload.head_pipeline).not_to be_nil
        end

        context 'when the MR has a branch head pipeline' do
          let!(:merge_request) do
            create(:merge_request, :with_head_pipeline, source_project: project)
          end

          it 'adds the status to the existing pipeline' do
            expect { response }.not_to change { ::Ci::Pipeline.count }
            expect(response.payload[:job].pipeline_id).to eq(merge_request.head_pipeline_id)
          end
        end

        context 'when the MR has a merged result head pipeline' do
          let!(:merge_request) do
            create(:merge_request, source_project: project, head_pipeline: head_pipeline)
          end

          let(:head_pipeline) { create(:ci_pipeline, :merged_result_pipeline) }

          it 'creates a new branch pipeline but does not change the head pipeline' do
            expect { response }
              .to change { ::Ci::Pipeline.count }.by(1)
              .and change { ::Ci::Stage.count }.by(1)
              .and change { ::CommitStatus.count }.by(1)

            expect(merge_request.reload.head_pipeline_id).to eq(head_pipeline.id)
          end
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

      let(:params) { parameters.merge(updatable_optional_attributes) }

      # creating the initial commit status
      before do
        execute_service(
          sha: sha,
          state: 'running',
          context: 'coverage',
          ref: 'master',
          description: 'coverage test',
          coverage: 10.0,
          target_url: 'http://gitlab.com/status'
        )
      end

      it 'updates a commit status' do
        expect { response }
          .to not_change { ::Ci::Pipeline.count }.from(1)
          .and not_change { ::Ci::Stage.count }.from(1)
          .and not_change { ::CommitStatus.count }.from(1)

        expect(response).to be_success
        expect(job.sha).to eq(commit.id)
        expect(job.status).to eq('success')
        expect(job.name).to eq('coverage')
        expect(job.ref).to eq('master')
        expect(job.coverage).to eq(90.0)
        expect(job.description).to eq('new description')
        expect(job.target_url).to eq('http://gitlab.com/status')
      end

      context 'when the `state` parameter is sent the same' do
        let(:parameters) do
          {
            sha: sha,
            state: 'running',
            name: 'coverage',
            ref: 'master'
          }
        end

        it 'does not update the commit status' do
          expect { response }
            .to not_change { ::Ci::Pipeline.count }.from(1)
            .and not_change { ::Ci::Stage.count }.from(1)
            .and not_change { ::CommitStatus.count }.from(1)

          expect(response).to be_error
          expect(response.http_status).to eq(:bad_request)
          expect(response.message).to eq(
            "Cannot transition status via :run from :running (Reason(s): Status cannot transition via \"run\")"
          )

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

      let(:ref) { 'master' }
      let(:params) do
        {
          sha: sha,
          pipeline_id: other_pipeline.id,
          state: 'success',
          ref: ref
        }
      end

      before do
        stub_const("#{described_class}::DEFAULT_LIMIT_PIPELINES", 3)
      end

      it 'update the correct pipeline', :sidekiq_might_not_need_inline do
        expect { response }
          .to not_change { ::Ci::Pipeline.count }.from(2)
          .and change { ::Ci::Stage.count }.by(1)
          .and change { ::CommitStatus.count }.by(1)

        expect(first_pipeline.reload.status).to eq('created')
        expect(other_pipeline.reload.status).to eq('success')
      end

      it 'create a status on an old pipeline', :sidekiq_might_not_need_inline do
        # 3 pipelines more are created to validate that it is possible to set a status on the 4th.
        (0..2).each do |_|
          project.ci_pipelines.build(source: :push, sha: commit.id, ref: 'master', status: 'created').tap do |p|
            p.ensure_project_iid!
            p.save!
          end
        end

        expect { response }
          .to not_change { ::Ci::Pipeline.count }.from(5)
          .and change { ::Ci::Stage.count }.by(1)
          .and change { ::CommitStatus.count }.by(1)

        expect(first_pipeline.reload.status).to eq('created')
        expect(other_pipeline.reload.status).to eq('success')
      end

      context 'when pipeline_id and sha do not match' do
        let(:other_commit) { create(:commit) }
        let(:sha) { other_commit.id }

        it 'returns a service error' do
          expect { response }
            .to not_change { ::Ci::Pipeline.count }.from(2)
            .and not_change { ::Ci::Stage.count }.from(0)
            .and not_change { ::CommitStatus.count }.from(0)

          expect(response).to be_error
          expect(response.http_status).to eq(:not_found)
          expect(response.message).to eq("404 Pipeline for pipeline_id, sha and ref Not Found")
        end

        context 'when an missing pipeline_id is provided' do
          let(:sha) { commit.id }
          let(:other_pipeline) do
            Struct.new(:id).new('FakeID')
          end

          it 'returns a service error' do
            expect { response }
              .to not_change { ::Ci::Pipeline.count }.from(1)
              .and not_change { ::Ci::Stage.count }.from(0)
              .and not_change { ::CommitStatus.count }.from(0)

            expect(response).to be_error
            expect(response.http_status).to eq(:not_found)
            expect(response.message).to eq("404 Pipeline for pipeline_id, sha and ref Not Found")
          end
        end
      end

      context 'when sha and pipeline_id match but ref does not' do
        let(:ref) { 'FakeRef' }

        it 'returns a service error' do
          expect { response }
            .to not_change { ::Ci::Pipeline.count }.from(2)
            .and not_change { ::Ci::Stage.count }.from(0)
            .and not_change { ::CommitStatus.count }.from(0)

          expect(response).to be_error
          expect(response.http_status).to eq(:not_found)
          expect(response.message).to eq("404 Pipeline for pipeline_id, sha and ref Not Found")
        end
      end
    end
  end

  context 'when retrying a commit status' do
    subject(:response) do
      execute_service(state: 'failed', name: 'test', ref: 'master')

      execute_service(state: 'success', name: 'test', ref: 'master')
    end

    it 'correctly posts a new commit status' do
      expect { response }
        .to change { ::Ci::Pipeline.count }.by(1)
        .and change { ::Ci::Stage.count }.by(1)
        .and change { ::CommitStatus.count }.by(2)

      expect(response).to be_success
      expect(job.sha).to eq(commit.id)
      expect(job.status).to eq('success')
    end

    it 'retries the commit status', :sidekiq_might_not_need_inline do
      response

      expect(CommitStatus.count).to eq 2
      expect(CommitStatus.first).to be_retried
      expect(CommitStatus.last.pipeline).to be_success
    end
  end

  context 'when status is invalid' do
    let(:params) { { state: 'invalid' } }

    it 'does not create commit status' do
      expect { response }
        .to change { ::Ci::Pipeline.count }.by(1)
        .and change { ::Ci::Stage.count }.by(1)
        .and not_change { ::CommitStatus.count }.from(0)

      expect(response).to be_error
      expect(response.http_status).to eq(:bad_request)
      expect(response.message).to eq('invalid state')
    end
  end

  context 'when request without a state made' do
    let(:params) { {} }

    it 'does not create commit status' do
      expect { response }
        .to not_change { ::Ci::Pipeline.count }.from(0)
        .and not_change { ::Ci::Stage.count }.from(0)
        .and not_change { ::CommitStatus.count }.from(0)

      expect(response).to be_error
      expect(response.http_status).to eq(:bad_request)
      expect(response.message).to eq('State is required')
    end
  end

  context 'when updating a protected ref' do
    let(:params) { { state: 'running', ref: 'master' } }

    before do
      create(:protected_branch, project: project, name: 'master')
    end

    context 'with user as developer' do
      let(:user) { developer }

      it 'does not create commit status' do
        expect { response }
          .to change { ::Ci::Pipeline.count }.by(1)
          .and not_change { ::Ci::Stage.count }.from(0)
          .and not_change { ::CommitStatus.count }.from(0)

        expect(response).to be_error
        expect(response.http_status).to eq(:forbidden)
        expect(response.message).to eq('403 Forbidden')
      end
    end

    context 'with user as maintainer' do
      let(:user) { create_user(:maintainer) }

      it 'creates commit status' do
        expect { response }
          .to change { ::Ci::Pipeline.count }.by(1)
          .and change { ::Ci::Stage.count }.by(1)
          .and change { ::CommitStatus.count }.by(1)

        expect(response).to be_success
      end
    end
  end

  context 'when commit SHA is invalid' do
    let(:sha) { 'invalid_sha' }
    let(:params) { { state: 'running', sha: sha } }

    it 'returns not found error' do
      expect { response }
        .to not_change { ::Ci::Pipeline.count }.from(0)
        .and not_change { ::Ci::Stage.count }.from(0)
        .and not_change { ::CommitStatus.count }.from(0)

      expect(response).to be_error
      expect(response.http_status).to eq(:not_found)
      expect(response.message).to eq('404 Commit Not Found')
    end
  end

  context 'when target URL is an invalid address' do
    let(:params) { { state: 'pending', target_url: 'invalid url' } }

    it 'responds with bad request status and validation errors' do
      expect { response }
        .to change { ::Ci::Pipeline.count }.by(1)
        .and change { ::Ci::Stage.count }.by(1)
        .and not_change { ::CommitStatus.count }.from(0)

      expect(response).to be_error
      expect(response.http_status).to eq(:bad_request)
      expect(response.message[:target_url])
        .to include 'is blocked: Only allowed schemes are http, https'
    end
  end

  context 'when target URL is an unsupported scheme' do
    let(:params) { { state: 'pending', target_url: 'git://example.com' } }

    it 'responds with bad request status and validation errors' do
      expect { response }
        .to change { ::Ci::Pipeline.count }.by(1)
        .and change { ::Ci::Stage.count }.by(1)
        .and not_change { ::CommitStatus.count }.from(0)

      expect(response).to be_error
      expect(response.http_status).to eq(:bad_request)
      expect(response.message[:target_url])
          .to include 'is blocked: Only allowed schemes are http, https'
    end
  end

  context 'when trying to update a status of a different type' do
    let!(:pipeline) { create(:ci_pipeline, project: project, sha: sha, ref: 'ref') }
    let!(:ci_build) { create(:ci_build, pipeline: pipeline, name: 'test-job') }
    let(:params) { { state: 'pending', name: 'test-job' } }

    before do
      execute_service(params)
    end

    it 'responds with bad request status and validation errors' do
      expect { response }
        .to not_change { ::Ci::Pipeline.count }.from(1)
        .and not_change { ::Ci::Stage.count }.from(2)
        .and not_change { ::CommitStatus.count }.from(1)

      expect(response).to be_error
      expect(response.http_status).to eq(:bad_request)
      expect(response.message[:name])
          .to include 'has already been taken'
    end
  end

  context 'with partitions' do
    include Ci::PartitioningHelpers

    let(:current_partition_id) { ci_testing_partition_id }
    let(:params) { { state: 'running' } }

    before do
      stub_current_partition_id(ci_testing_partition_id)
    end

    it 'creates records in the current partition' do
      expect { response }
        .to change { ::Ci::Pipeline.count }.by(1)
        .and change { ::Ci::Stage.count }.by(1)
        .and change { ::CommitStatus.count }.by(1)

      expect(response).to be_success

      status = CommitStatus.find(job.id)

      expect(status.partition_id).to eq(current_partition_id)
      expect(status.pipeline.partition_id).to eq(current_partition_id)
    end
  end

  context 'for race condition' do
    let(:licenses_snyk_params) { { state: 'running', name: 'licenses', description: 'testing' } }
    let(:security_snyk_params) { { state: 'running', name: 'security', description: 'testing' } }
    let(:snyk_params_list) { [licenses_snyk_params, security_snyk_params] }

    it 'creates one pipeline and two jobs (one for licenses, one for security)' do
      expect do
        snyk_params_list.map do |snyk_params|
          Thread.new do
            response = Gitlab::ExclusiveLease.skipping_transaction_check { execute_service(snyk_params) }
            expect(response).to be_success
          end
        end.each(&:join)
      end
        .to change { ::Ci::Pipeline.count }.by(1)
        .and change { ::Ci::Stage.count }.by(1)
        .and change { ::CommitStatus.count }.by(2)
    end
  end

  def create_user(access_level_trait)
    user = create(:user)
    create(:project_member, access_level_trait, user: user, project: project)
    user
  end

  def execute_service(params = self.params)
    described_class
      .new(project, user, params)
      .execute(optional_commit_status_params: params.slice(*%i[target_url description coverage]))
  end
end
