# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Runner, :clean_gitlab_redis_trace_chunks, feature_category: :runner do
  include StubGitlabCalls
  include RedisHelpers
  include WorkhorseHelpers

  let(:registration_token) { 'abcdefg123456' }

  before do
    stub_feature_flags(ci_enable_live_trace: true)
    stub_gitlab_calls
    stub_application_setting(runners_registration_token: registration_token)
    allow_any_instance_of(::Ci::Runner).to receive(:cache_attributes)
  end

  describe '/api/v4/jobs' do
    let(:group) { create(:group, :nested) }
    let(:project) { create(:project, namespace: group, shared_runners_enabled: false) }
    let(:pipeline) { create(:ci_pipeline, project: project, ref: 'master') }
    let(:runner) { create(:ci_runner, :project, projects: [project]) }
    let(:user) { create(:user) }
    let(:job) do
      create(
        :ci_build,
        :artifacts,
        :extended_options,
        pipeline: pipeline,
        name: 'spinach',
        stage: 'test',
        stage_idx: 0
      )
    end

    describe 'PATCH /api/v4/jobs/:id/trace' do
      let(:job) do
        create(
          :ci_build,
          :running,
          :trace_live,
          project: project,
          user: user,
          runner_id: runner.id,
          pipeline: pipeline
        )
      end

      let(:headers) { { API::Ci::Helpers::Runner::JOB_TOKEN_HEADER => job.token, 'Content-Type' => 'text/plain' } }
      let(:headers_with_range) { headers.merge({ 'Content-Range' => '11-20' }) }
      let(:update_interval) { 10.seconds }

      before do
        initial_patch_the_trace
      end

      it_behaves_like 'API::CI::Runner application context metadata', 'PATCH /api/:version/jobs/:id/trace' do
        let(:send_request) { patch_the_trace }
      end

      it_behaves_like 'runner migrations backoff' do
        let(:request) { patch_the_trace }
      end

      it 'updates runner info' do
        runner.update!(contacted_at: 1.year.ago)

        expect { patch_the_trace }.to change { runner.reload.contacted_at }
      end

      context 'when request is valid' do
        it 'gets correct response' do
          expect(response).to have_gitlab_http_status(:accepted)
          expect(job.reload.trace.raw).to eq 'BUILD TRACE appended'
          expect(response.header).to have_key 'Range'
          expect(response.header).to have_key 'Job-Status'
          expect(response.header).to have_key 'X-GitLab-Trace-Update-Interval'
        end

        context 'when job has been updated recently' do
          it { expect { patch_the_trace }.not_to change { job.updated_at } }

          it "changes the job's trace" do
            patch_the_trace

            expect(job.reload.trace.raw).to eq 'BUILD TRACE appended appended'
          end

          context 'when Runner makes a force-patch' do
            it { expect { force_patch_the_trace }.not_to change { job.updated_at } }

            it "doesn't change the build.trace" do
              force_patch_the_trace

              expect(job.reload.trace.raw).to eq 'BUILD TRACE appended'
            end
          end
        end

        context 'when job was not updated recently' do
          let(:update_interval) { 16.minutes }

          it { expect { patch_the_trace }.to change { job.updated_at } }

          it 'changes the job.trace' do
            patch_the_trace

            expect(job.reload.trace.raw).to eq 'BUILD TRACE appended appended'
          end

          context 'when Runner makes a force-patch' do
            it { expect { force_patch_the_trace }.to change { job.updated_at } }

            it "doesn't change the job.trace" do
              force_patch_the_trace

              expect(job.reload.trace.raw).to eq 'BUILD TRACE appended'
            end
          end
        end

        context 'when project for the build has been deleted' do
          let(:job) do
            create(:ci_build, :running, :trace_live, runner_id: runner.id, pipeline: pipeline) do |job|
              job.project.update!(pending_delete: true)
            end
          end

          it 'responds with forbidden' do
            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'when trace is patched' do
          before do
            patch_the_trace
          end

          it 'has valid trace' do
            expect(response).to have_gitlab_http_status(:accepted)
            expect(job.reload.trace.raw).to eq 'BUILD TRACE appended appended'
          end

          context 'when canceling is supported' do
            include_context 'when canceling support'

            context 'when job is cancelled' do
              before do
                job.cancel
              end

              it 'patching the trace is allowed' do
                patch_the_trace

                expect(response).to have_gitlab_http_status(:accepted)
              end
            end
          end

          context 'when canceling is not supported' do
            context 'when job is canceled' do
              before do
                job.cancel
              end

              it 'patching the trace returns forbidden' do
                patch_the_trace

                expect(response).to have_gitlab_http_status(:forbidden)
              end
            end
          end

          context 'when redis data are flushed' do
            before do
              redis_trace_chunks_cleanup!
            end

            it 'has empty trace' do
              expect(job.reload.trace.raw).to eq ''
            end

            context 'when we perform partial patch' do
              before do
                patch_the_trace('hello', headers.merge({ 'Content-Range' => "28-32/5" }))
              end

              it 'returns an error' do
                expect(response).to have_gitlab_http_status(:range_not_satisfiable)
                expect(response.header['Range']).to eq('0-0')
              end
            end

            context 'when we resend full trace' do
              before do
                patch_the_trace('BUILD TRACE appended appended hello', headers.merge({ 'Content-Range' => "0-34/35" }))
              end

              it 'succeeds with updating trace' do
                expect(response).to have_gitlab_http_status(:accepted)
                expect(job.reload.trace.raw).to eq 'BUILD TRACE appended appended hello'
              end
            end
          end
        end

        context 'when concurrent update of trace is happening' do
          before do
            job.trace.write('wb') do
              patch_the_trace
            end
          end

          it 'returns that operation conflicts' do
            expect(response).to have_gitlab_http_status(:conflict)
          end
        end

        context 'when canceling is supported' do
          include_context 'when canceling support'

          it 'receives status in header' do
            job.cancel
            patch_the_trace

            expect(response.header['Job-Status']).to eq 'canceling'
          end
        end

        context 'when canceling is not supported' do
          it 'receives status in header' do
            job.cancel
            patch_the_trace

            expect(response.header['Job-Status']).to eq 'canceled'
          end
        end

        context 'when build trace is being watched' do
          before do
            job.trace.being_watched!
          end

          it 'returns X-GitLab-Trace-Update-Interval as 3' do
            patch_the_trace

            expect(response).to have_gitlab_http_status(:accepted)
            expect(response.header['X-GitLab-Trace-Update-Interval']).to eq('3')
          end
        end

        context 'when build trace is not being watched' do
          it 'returns the interval in X-GitLab-Trace-Update-Interval' do
            patch_the_trace

            expect(response).to have_gitlab_http_status(:accepted)
            expect(response.header['X-GitLab-Trace-Update-Interval']).to eq('60')
          end
        end
      end

      context 'when job does not exist anymore' do
        it 'returns 403 Forbidden' do
          patch_the_trace(job_id: non_existing_record_id)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when Runner makes a force-patch' do
        before do
          force_patch_the_trace
        end

        it 'gets correct response' do
          expect(response).to have_gitlab_http_status(:accepted)
          expect(job.reload.trace.raw).to eq 'BUILD TRACE appended'
          expect(response.header).to have_key 'Range'
          expect(response.header).to have_key 'Job-Status'
        end
      end

      context 'when content-range start is too big' do
        let(:headers_with_range) { headers.merge({ 'Content-Range' => '15-20/6' }) }

        it 'gets 416 error response with range headers' do
          expect(response).to have_gitlab_http_status(:range_not_satisfiable)
          expect(response.header).to have_key 'Range'
          expect(response.header['Range']).to eq '0-11'
        end
      end

      context 'when content-range start is too small' do
        let(:headers_with_range) { headers.merge({ 'Content-Range' => '8-20/13' }) }

        it 'gets 416 error response with range headers' do
          expect(response).to have_gitlab_http_status(:range_not_satisfiable)
          expect(response.header).to have_key 'Range'
          expect(response.header['Range']).to eq '0-11'
        end
      end

      context 'when Content-Range header is missing' do
        let(:headers_with_range) { headers }

        it { expect(response).to have_gitlab_http_status(:bad_request) }
      end

      context 'when job has been errased' do
        let(:job) { create(:ci_build, runner_id: runner.id, erased_at: Time.now) }

        it { expect(response).to have_gitlab_http_status(:forbidden) }
      end

      context 'when the job log is too big' do
        before do
          project.actual_limits.update!(ci_jobs_trace_size_limit: 1)
        end

        it 'returns 403 Forbidden' do
          patch_the_trace(' appended', headers.merge({ 'Content-Range' => "#{1.megabyte}-#{1.megabyte + 9}" }))

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      def patch_the_trace(content = ' appended', request_headers = nil, job_id: job.id)
        unless request_headers
          job.trace.read do |stream|
            offset = stream.size
            limit = offset + content.length - 1
            request_headers = headers.merge({ 'Content-Range' => "#{offset}-#{limit}" })
          end
        end

        travel_to(job.updated_at + update_interval) do
          patch api("/jobs/#{job_id}/trace"), params: content, headers: request_headers
        end
        job.reload
      end

      def initial_patch_the_trace
        patch_the_trace(' appended', headers_with_range)
      end

      def force_patch_the_trace
        2.times { patch_the_trace('') }
      end
    end
  end
end
