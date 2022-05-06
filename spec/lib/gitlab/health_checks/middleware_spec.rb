# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::HealthChecks::Middleware do
  let(:app) { instance_double(Proc) }
  let(:env) { { 'PATH_INFO' => path } }

  let(:readiness_probe) { instance_double(Gitlab::HealthChecks::Probes::Collection) }
  let(:liveness_probe) { instance_double(Gitlab::HealthChecks::Probes::Collection) }
  let(:probe_result) { Gitlab::HealthChecks::Probes::Status.new(200, { status: 'ok' }) }

  subject(:middleware) { described_class.new(app, readiness_probe, liveness_probe) }

  describe '#call' do
    context 'handling /readiness requests' do
      let(:path) { '/readiness' }

      it 'handles the request' do
        expect(readiness_probe).to receive(:execute).and_return(probe_result)

        response = middleware.call(env)

        expect(response).to eq([200, { 'Content-Type' => 'application/json; charset=utf-8' }, ['{"status":"ok"}']])
      end
    end

    context 'handling /liveness requests' do
      let(:path) { '/liveness' }

      it 'handles the request' do
        expect(liveness_probe).to receive(:execute).and_return(probe_result)

        response = middleware.call(env)

        expect(response).to eq([200, { 'Content-Type' => 'application/json; charset=utf-8' }, ['{"status":"ok"}']])
      end
    end

    context 'handling other requests' do
      let(:path) { '/other_path' }

      it 'forwards them to the next middleware' do
        expect(app).to receive(:call).with(env).and_return([201, {}, []])

        response = middleware.call(env)

        expect(response).to eq([201, {}, []])
      end
    end
  end
end
