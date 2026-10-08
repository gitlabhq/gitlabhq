# frozen_string_literal: true

require 'spec_helper'
require 'rack'
require 'request_store'
require 'gitlab/rspec/next_instance_of'

RSpec.describe Gitlab::Middleware::RequestContext, feature_category: :application_instrumentation do
  include NextInstanceOf

  let(:app) { ->(env) {} }
  let(:env) { {} }

  around do |example|
    RequestStore.begin!
    example.run
    RequestStore.end!
    RequestStore.clear!
  end

  describe '#call' do
    let(:instance) { Gitlab::RequestContext.instance }

    subject { described_class.new(app).call(env) }

    context 'GVL instrumentation' do
      let(:env) { Rack::MockRequest.env_for("/") }

      it 'enables the GVL timers' do
        expect(GVLTools::LocalTimer).to receive(:enable)
        expect(GVLTools::GlobalTimer).to receive(:enable)

        subject
      end

      context 'when the timers start disabled' do
        before do
          ::Gitlab::Instrumentation::Gvl.toggle(false)
        end

        after do
          ::Gitlab::Instrumentation::Gvl.toggle(false)
        end

        it 'records the thread timer baseline after enabling the timers' do
          allow(GVLTools::LocalTimer).to receive(:monotonic_time).and_return(42)

          expect { subject }.to change { instance.gvl_local_timer_start }.from(nil).to(42)
        end
      end

      context 'when enable_puma_gvl_metrics is disabled' do
        before do
          stub_feature_flags(enable_puma_gvl_metrics: false)
        end

        it 'disables the GVL timers' do
          expect(GVLTools::LocalTimer).to receive(:disable)
          expect(GVLTools::GlobalTimer).to receive(:disable)

          subject
        end
      end
    end

    context 'setting the client ip' do
      context 'with X-Forwarded-For headers' do
        let(:load_balancer_ip) { '1.2.3.4' }
        let(:headers) do
          {
            'HTTP_X_FORWARDED_FOR' => "#{load_balancer_ip}, 127.0.0.1",
            'REMOTE_ADDR' => '127.0.0.1'
          }
        end

        let(:env) { Rack::MockRequest.env_for("/").merge(headers) }

        it 'returns the load balancer IP' do
          expect { subject }.to change { instance.client_ip }.from(nil).to(load_balancer_ip)
        end
      end

      context 'request' do
        let(:ip) { '192.168.1.11' }

        before do
          allow_next_instance_of(Rack::Request) do |request|
            allow(request).to receive(:ip).and_return(ip)
          end
        end

        it 'sets the `client_ip`' do
          expect { subject }.to change { instance.client_ip }.from(nil).to(ip)
        end

        it 'sets the `request_start_time`' do
          expect { subject }.to change { instance.request_start_time }.from(nil).to(Float)
        end

        it 'sets the `spam_params`' do
          expect { subject }.to change { instance.spam_params }.from(nil).to(::Spam::SpamParams)
        end
      end
    end

    context 'setting the user agent' do
      let(:user_agent) { 'GitLabMobile/1.2.0 (iOS 26.0.1; build 45)' }
      let(:env) { Rack::MockRequest.env_for("/").merge('HTTP_USER_AGENT' => user_agent) }

      it 'sets the `user_agent`' do
        expect { subject }.to change { instance.user_agent }.from(nil).to(user_agent)
      end
    end

    context 'setting the client identity' do
      let(:env) do
        Rack::MockRequest.env_for("/").merge(
          'HTTP_X_GITLAB_CLIENT_TYPE' => 'mobile',
          'HTTP_X_GITLAB_CLIENT_NAME' => 'gitlab-mobile-ios',
          'HTTP_X_GITLAB_CLIENT_VERSION' => '1.2.0'
        )
      end

      let(:seen_context) { {} }
      let(:app) do
        ->(_env) do
          seen_context.merge!(Gitlab::ApplicationContext.current)
          [200, {}, ['OK']]
        end
      end

      it 'exposes it to the app through the application context' do
        subject

        expect(seen_context).to include(
          'meta.client_type' => 'mobile',
          'meta.client_name' => 'gitlab-mobile-ios',
          'meta.client_version' => '1.2.0'
        )
      end
    end
  end
end
