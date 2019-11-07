# frozen_string_literal: true

require 'spec_helper'

describe HealthController do
  include StubENV

  let(:token) { Gitlab::CurrentSettings.health_check_access_token }
  let(:whitelisted_ip) { '1.1.1.1' }
  let(:not_whitelisted_ip) { '2.2.2.2' }
  let(:params) { {} }
  let(:headers) { {} }

  before do
    allow(Settings.monitoring).to receive(:ip_whitelist).and_return([whitelisted_ip])
    stub_storage_settings({}) # Hide the broken storage
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  shared_context 'endpoint querying database' do
    it 'does query database' do
      control_count = ActiveRecord::QueryRecorder.new { subject }.count

      expect(control_count).not_to be_zero
    end
  end

  shared_context 'endpoint not querying database' do
    it 'does not query database' do
      control_count = ActiveRecord::QueryRecorder.new { subject }.count

      expect(control_count).to be_zero
    end
  end

  shared_context 'endpoint not found' do
    it 'responds with resource not found' do
      subject

      expect(response.status).to eq(404)
    end
  end

  describe 'GET /-/health' do
    subject { get '/-/health', params: params, headers: headers }

    shared_context 'endpoint responding with health data' do
      it 'responds with health checks data' do
        subject

        expect(response.status).to eq(200)
        expect(response.body).to eq('GitLab OK')
      end
    end

    context 'accessed from whitelisted ip' do
      before do
        stub_remote_addr(whitelisted_ip)
      end

      it_behaves_like 'endpoint responding with health data'
      it_behaves_like 'endpoint not querying database'
    end

    context 'accessed from not whitelisted ip' do
      before do
        stub_remote_addr(not_whitelisted_ip)
      end

      it_behaves_like 'endpoint not querying database'
      it_behaves_like 'endpoint not found'
    end
  end

  describe 'GET /-/readiness' do
    subject { get '/-/readiness', params: params, headers: headers }

    shared_context 'endpoint responding with readiness data' do
      context 'when requesting instance-checks' do
        it 'responds with readiness checks data' do
          expect(Gitlab::HealthChecks::MasterCheck).to receive(:check) { true }

          subject

          expect(json_response).to include({ 'status' => 'ok' })
          expect(json_response['master_check']).to contain_exactly({ 'status' => 'ok' })
        end

        it 'responds with readiness checks data when a failure happens' do
          expect(Gitlab::HealthChecks::MasterCheck).to receive(:check) { false }

          subject

          expect(json_response).to include({ 'status' => 'failed' })
          expect(json_response['master_check']).to contain_exactly(
            { 'status' => 'failed', 'message' => 'unexpected Master check result: false' })

          expect(response.status).to eq(503)
          expect(response.headers['X-GitLab-Custom-Error']).to eq(1)
        end
      end

      context 'when requesting all checks' do
        before do
          params.merge!(all: true)
        end

        it 'responds with readiness checks data' do
          subject

          expect(json_response['db_check']).to contain_exactly({ 'status' => 'ok' })
          expect(json_response['cache_check']).to contain_exactly({ 'status' => 'ok' })
          expect(json_response['queues_check']).to contain_exactly({ 'status' => 'ok' })
          expect(json_response['shared_state_check']).to contain_exactly({ 'status' => 'ok' })
          expect(json_response['gitaly_check']).to contain_exactly(
            { 'status' => 'ok', 'labels' => { 'shard' => 'default' } })
        end

        it 'responds with readiness checks data when a failure happens' do
          allow(Gitlab::HealthChecks::Redis::RedisCheck).to receive(:readiness).and_return(
            Gitlab::HealthChecks::Result.new('redis_check', false, "check error"))

          subject

          expect(json_response['cache_check']).to contain_exactly({ 'status' => 'ok' })
          expect(json_response['redis_check']).to contain_exactly(
            { 'status' => 'failed', 'message' => 'check error' })

          expect(response.status).to eq(503)
          expect(response.headers['X-GitLab-Custom-Error']).to eq(1)
        end
      end
    end

    context 'accessed from whitelisted ip' do
      before do
        stub_remote_addr(whitelisted_ip)
      end

      it_behaves_like 'endpoint not querying database'
      it_behaves_like 'endpoint responding with readiness data'

      context 'when requesting all checks' do
        before do
          params.merge!(all: true)
        end

        it_behaves_like 'endpoint querying database'
      end
    end

    context 'accessed from not whitelisted ip' do
      before do
        stub_remote_addr(not_whitelisted_ip)
      end

      it_behaves_like 'endpoint not querying database'
      it_behaves_like 'endpoint not found'
    end

    context 'accessed with valid token' do
      context 'token passed in request header' do
        let(:headers) { { TOKEN: token } }

        it_behaves_like 'endpoint responding with readiness data'
        it_behaves_like 'endpoint querying database'
      end

      context 'token passed as URL param' do
        let(:params) { { token: token } }

        it_behaves_like 'endpoint responding with readiness data'
        it_behaves_like 'endpoint querying database'
      end
    end
  end

  describe 'GET /-/liveness' do
    subject { get '/-/liveness', params: params, headers: headers }

    shared_context 'endpoint responding with liveness data' do
      it 'responds with liveness checks data' do
        subject

        expect(json_response).to eq('status' => 'ok')
      end
    end

    context 'accessed from whitelisted ip' do
      before do
        stub_remote_addr(whitelisted_ip)
      end

      it_behaves_like 'endpoint not querying database'
      it_behaves_like 'endpoint responding with liveness data'
    end

    context 'accessed from not whitelisted ip' do
      before do
        stub_remote_addr(not_whitelisted_ip)
      end

      it_behaves_like 'endpoint not querying database'
      it_behaves_like 'endpoint not found'

      context 'accessed with valid token' do
        context 'token passed in request header' do
          let(:headers) { { TOKEN: token } }

          it_behaves_like 'endpoint responding with liveness data'
          it_behaves_like 'endpoint querying database'
        end

        context 'token passed as URL param' do
          let(:params) { { token: token } }

          it_behaves_like 'endpoint responding with liveness data'
          it_behaves_like 'endpoint querying database'
        end
      end
    end
  end

  def stub_remote_addr(ip)
    headers.merge!(REMOTE_ADDR: ip)
  end
end
