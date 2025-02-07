# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Runner, :clean_gitlab_redis_shared_state, feature_category: :runner do
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

  describe '/api/v4/runners' do
    describe 'POST /api/v4/runners/verify', :freeze_time do
      let_it_be_with_reload(:runner) { create(:ci_runner, token_expires_at: 3.days.from_now) }

      let(:params) { nil }

      subject(:verify) { post api('/runners/verify'), params: params }

      it_behaves_like 'runner migrations backoff' do
        let(:request) { verify }
      end

      context 'when no token is provided' do
        it 'returns 400 error' do
          verify

          expect(response).to have_gitlab_http_status :bad_request
        end
      end

      context 'when invalid token is provided' do
        let(:params) { { token: 'invalid-token' } }

        it 'returns 403 error' do
          verify

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when valid token is provided' do
        let(:params) { { token: runner.token } }

        context 'with glrt-prefixed token' do
          let_it_be(:registration_token) { 'glrt-abcdefg123456' }
          let_it_be(:registration_type) { :authenticated_user }
          let_it_be(:runner) do
            create(:ci_runner, registration_type: registration_type,
              token: registration_token, token_expires_at: 3.days.from_now)
          end

          it 'verifies Runner credentials' do
            verify

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to eq({
              'id' => runner.id,
              'token' => runner.token,
              'token_expires_at' => runner.token_expires_at.iso8601(3)
            })
          end

          it 'does not update contacted_at' do
            expect { verify }.not_to change { runner.reload.contacted_at }.from(nil)
          end

          # TODO: Remove in https://gitlab.com/gitlab-org/gitlab/-/issues/504963 (when ci_runners is swapped)
          # This is because the new table will have check constraints for these scenarios, and therefore
          # any orphaned runners will be missing
          context 'when runner is missing sharding_key_id', :aggregate_failures do
            let(:connection) { Ci::ApplicationRecord.connection }
            let(:params) { { token: 'foo' } }
            let(:non_partitioned_runner) do
              connection.execute(<<~SQL)
                INSERT INTO ci_runners(created_at, runner_type, token, sharding_key_id)
                  VALUES(NOW(), #{runner_type}, '#{params[:token]}', NULL);
              SQL

              Ci::Runner.where(runner_type: runner_type).last
            end

            before do
              # Allow creating legacy runners that are not present in the partitioned table (created when FK was not
              # present)
              connection.transaction do
                connection.execute(<<~SQL)
                  ALTER TABLE ci_runners DISABLE TRIGGER ALL;
                SQL

                non_partitioned_runner

                connection.execute(<<~SQL)
                  ALTER TABLE ci_runners ENABLE TRIGGER ALL;
                SQL
              end
            end

            context 'when group runner is missing sharding_key_id' do
              let(:runner_type) { 2 }
              let(:runner) { non_partitioned_runner }

              it 'returns forbidden status code', :aggregate_failures do
                expect { verify }.not_to change { partitioned_runner_exists?(runner) }.from(false)
                expect(response).to have_gitlab_http_status(:forbidden)
                expect(response.body).to eq({ message: '403 Forbidden - Runner is orphaned' }.to_json)
              end
            end

            context 'when project runner is missing sharding_key_id' do
              let(:runner_type) { 3 }
              let(:runner) { non_partitioned_runner }

              it 'returns forbidden status code', :aggregate_failures do
                expect { verify }.not_to change { partitioned_runner_exists?(runner) }.from(false)
                expect(response).to have_gitlab_http_status(:forbidden)
                expect(response.body).to eq({ message: '403 Forbidden - Runner is orphaned' }.to_json)
              end

              # TODO: Remove once https://gitlab.com/gitlab-org/gitlab/-/issues/516929 is closed.
              context 'with reject_orphaned_runners FF disabled' do
                before do
                  stub_feature_flags(reject_orphaned_runners: false)
                end

                it 'does not update contacted_at and returns error', :aggregate_failures do
                  expect { verify }.not_to change { partitioned_runner_exists?(non_partitioned_runner) }.from(false)

                  expect(response).to have_gitlab_http_status(:unprocessable_entity)
                  expect(response.body).to eq({ message: 'Runner is orphaned' }.to_json)
                  expect(non_partitioned_runner.contacted_at).to be_nil
                end
              end
            end

            private

            def partitioned_runner_exists?(runner)
              result = connection.execute(<<~SQL)
                SELECT COUNT(*) FROM ci_runners_e59bb2812d WHERE id = #{runner.id};
              SQL

              result.first['count'].positive?
            end
          end
        end

        it 'verifies Runner credentials' do
          verify

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq(
            'id' => runner.id,
            'token' => runner.token,
            'token_expires_at' => runner.token_expires_at.iso8601(3)
          )
        end

        it 'updates contacted_at' do
          expect { verify }.to change { runner.reload.contacted_at }.from(nil).to(Time.current)
        end

        context 'with non-expiring runner token' do
          before do
            runner.update!(token_expires_at: nil)
          end

          it 'verifies Runner credentials' do
            verify

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to eq(
              'id' => runner.id,
              'token' => runner.token,
              'token_expires_at' => nil
            )
          end
        end

        it_behaves_like 'storing arguments in the application context for the API' do
          let(:expected_params) { { client_id: "runner/#{runner.id}" } }
        end

        context 'when system_id is provided' do
          let(:params) { { token: runner.token, system_id: 's_some_system_id' } }

          it 'creates a runner_manager' do
            expect { verify }.to change { Ci::RunnerManager.count }.by(1)
          end
        end
      end

      context 'when non-expired token is provided' do
        let(:params) { { token: runner.token } }

        it 'verifies Runner credentials' do
          runner["token_expires_at"] = 10.days.from_now
          runner.save!
          verify

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq(
            'id' => runner.id,
            'token' => runner.token,
            'token_expires_at' => runner.token_expires_at.iso8601(3)
          )
        end
      end

      context 'when expired token is provided' do
        let(:params) { { token: runner.token } }

        it 'does not verify Runner credentials' do
          runner["token_expires_at"] = 10.days.ago
          runner.save!
          verify

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end
  end
end
