# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::InternalApiAuthenticator, feature_category: :api do
  let(:request) { instance_double(ActionDispatch::Request, path: '', env: {}) }
  let(:env) { {} }

  before do
    allow(Gitlab.config.gitlab).to receive(:relative_url_root).and_return('')
  end

  describe '.verify!' do
    it 'creates instance and calls verify!' do
      allow(request).to receive_messages(path: '/api/v4/internal/unknown', env: env)

      result = described_class.verify!(request)

      expect(result).to be false
    end
  end

  describe '#initialize' do
    it 'normalizes request headers from env' do
      env = {
        'HTTP_AUTHORIZATION' => 'Bearer token',
        'HTTP_JOB_TOKEN' => 'job123',
        'CONTENT_TYPE' => 'application/json',
        'CONTENT_LENGTH' => '100'
      }

      allow(request).to receive_messages(path: '/api/v4/internal/allowed', env: env)

      authenticator = described_class.new(request)

      headers = authenticator.instance_variable_get(:@headers)
      expect(headers['Authorization']).to eq('Bearer token')
      expect(headers['Job-Token']).to eq('job123')
      expect(headers['Content-Type']).to eq('application/json')
      expect(headers['Content-Length']).to eq('100')
    end

    it 'strips relative URL root from path' do
      allow(Gitlab.config.gitlab).to receive(:relative_url_root).and_return('/gitlab')
      allow(request).to receive_messages(path: '/gitlab/api/v4/internal/kas/usage_metrics', env: {})

      authenticator = described_class.new(request)

      path = authenticator.instance_variable_get(:@path)
      expect(path).to eq('/api/v4/internal/kas/usage_metrics')
    end
  end

  describe '#verify!' do
    subject(:authenticator) { described_class.new(request) }

    context 'when path does not match any route' do
      before do
        allow(request).to receive_messages(path: '/api/v4/unknown', env: {})
      end

      it 'returns false' do
        expect(authenticator.verify!).to be_falsey
      end
    end

    describe 'Kubernetes (KAS)' do
      before do
        allow(request).to receive_messages(path: '/api/v4/internal/kubernetes/agent_config', env: {})
      end

      it 'calls verify_kas verifier' do
        expect(::Gitlab::Kas).to receive(:verify_api_request).and_return(true)

        expect(authenticator.verify!).to be_truthy
      end

      context 'when verification raises StandardError' do
        it 'catches error and returns false' do
          expect(::Gitlab::Kas).to receive(:verify_api_request).and_raise(StandardError)
          expect(Gitlab::AppLogger).to receive(:info)

          expect(authenticator.verify!).to be_falsey
        end
      end
    end

    describe 'Workhorse' do
      before do
        allow(request).to receive_messages(path: '/api/v4/internal/workhorse/authorize', env: {})
      end

      it 'calls verify_workhorse verifier' do
        expect(::Gitlab::Workhorse).to receive(:verify_api_request!).with({})

        expect(authenticator.verify!).to be_truthy
      end

      context 'when verification raises error' do
        it 'catches error and returns false' do
          expect(::Gitlab::Workhorse).to receive(:verify_api_request!).and_raise(StandardError)
          expect(Gitlab::AppLogger).to receive(:info)

          expect(authenticator.verify!).to be_falsey
        end
      end
    end

    describe 'Internal Base Access' do
      %w[allowed lfs_authenticate two_factor personal_access_token pre_receive post_receive].each do |endpoint|
        context "when request is from #{endpoint} endpoint" do
          before do
            allow(request).to receive_messages(path: "/api/v4/internal/#{endpoint}", env: {})
          end

          it 'calls verify_shell' do
            expect(::Gitlab::Shell).to receive(:verify_api_request).and_return(true)

            expect(authenticator.verify!).to be_truthy
          end
        end
      end

      context 'when verification raises StandardError' do
        before do
          allow(request).to receive_messages(path: '/api/v4/internal/allowed', env: {})
        end

        it 'catches error and returns false' do
          expect(::Gitlab::Shell).to receive(:verify_api_request).and_raise(StandardError)
          expect(Gitlab::AppLogger).to receive(:info)

          expect(authenticator.verify!).to be_falsey
        end
      end
    end

    describe 'Search Zoekt' do
      before do
        allow(request).to receive_messages(path: '/api/v4/internal/search/zoekt/search', env: {})
      end

      it 'calls verify_shell' do
        expect(::Gitlab::Shell).to receive(:verify_api_request).and_return(true)

        expect(authenticator.verify!).to be_truthy
      end
    end

    describe 'Observability' do
      before do
        allow(request).to receive_messages(path: '/api/v4/internal/observability/metrics', env: {})
      end

      it 'calls verify_workhorse' do
        expect(::Gitlab::Workhorse).to receive(:verify_api_request!).with({})

        expect(authenticator.verify!).to be_truthy
      end
    end

    describe 'Shellhorse (Shell or Workhorse)' do
      before do
        allow(request).to receive_messages(path: '/api/v4/internal/shellhorse/test', env: {})
      end

      context 'when Shell header is present' do
        before do
          allow(request).to receive(:env).and_return({ 'HTTP_GITLAB_SHELL_SECRET_TOKEN' => 'shell_token' })
        end

        it 'uses Shell verification' do
          expect(::Gitlab::Shell).to receive(:header_set?).and_return(true)
          expect(::Gitlab::Shell).to receive(:verify_api_request).and_return(true)

          expect(authenticator.verify!).to be_truthy
        end
      end

      context 'when Shell header is absent' do
        it 'uses Workhorse verification' do
          expect(::Gitlab::Shell).to receive(:header_set?).and_return(false)
          expect(::Gitlab::Workhorse).to receive(:verify_api_request!).with({})

          expect(authenticator.verify!).to be_truthy
        end
      end

      context 'when verification raises StandardError' do
        it 'catches error and returns false' do
          expect(::Gitlab::Shell).to receive(:header_set?).and_raise(StandardError)
          expect(Gitlab::AppLogger).to receive(:info)

          expect(authenticator.verify!).to be_falsey
        end
      end
    end

    describe 'Secrets Manager (OpenBao)' do
      before do
        allow(request).to receive_messages(path: '/api/v4/internal/secrets_manager/secret',
          env: { 'HTTP_GITLAB_OPENBAO_AUTH_TOKEN' => 'token123' })
      end

      context 'when token is valid' do
        it 'returns true' do
          expect(authenticator).to receive(:read_openbao_secret_token).and_return('token123')

          expect(authenticator.verify!).to be_truthy
        end
      end

      context 'when token is missing from headers' do
        before do
          allow(request).to receive(:env).and_return({})
        end

        it 'returns false' do
          expect(authenticator.verify!).to be_falsey
        end
      end

      context 'when secret file token is missing' do
        it 'returns false' do
          expect(authenticator).to receive(:read_openbao_secret_token).and_return(nil)

          expect(authenticator.verify!).to be_falsey
        end
      end

      context 'when tokens do not match' do
        it 'returns false' do
          expect(authenticator).to receive(:read_openbao_secret_token).and_return('different_token')

          expect(authenticator.verify!).to be_falsey
        end
      end

      context 'when verification raises StandardError' do
        it 'catches error and returns false' do
          expect(::Rack::Utils).to receive(:secure_compare).and_raise(StandardError)
          expect(authenticator).to receive(:read_openbao_secret_token).and_return('token123')
          expect(Gitlab::AppLogger).to receive(:info)

          expect(authenticator.verify!).to be_falsey
        end
      end
    end

    describe '#read_openbao_secret_token' do
      subject(:authenticator) do
        allow(request).to receive_messages(path: '/api/v4/internal/secrets_manager/secret', env: {})
        described_class.new(request)
      end

      # Create the temp file inside Rails.root so the allowed-path check passes
      let(:token_dir)  { Rails.root.join('tmp') }
      let(:token_file) { Tempfile.new('openbao_token', token_dir) }

      before do
        token_file.write('super_secret_token')
        token_file.flush

        openbao_config = Gitlab.config.openbao.to_h
        openbao_config['authentication_token_secret_file_path'] = token_file.path
        allow(Gitlab.config).to receive(:openbao).and_return(openbao_config)
      end

      after do
        token_file.close!
      end

      context 'when the file exists and is within an allowed path' do
        it 'returns the token' do
          expect(authenticator.send(:read_openbao_secret_token)).to eq('super_secret_token')
        end

        it 'strips trailing newlines' do
          token_file.rewind
          token_file.truncate(0)
          token_file.write("super_secret_token\n")
          token_file.flush

          expect(authenticator.send(:read_openbao_secret_token)).to eq('super_secret_token')
        end
      end

      context 'when no file path is configured' do
        before do
          openbao_config = Gitlab.config.openbao.to_h
          openbao_config['authentication_token_secret_file_path'] = nil
          allow(Gitlab.config).to receive(:openbao).and_return(openbao_config)
        end

        it 'returns nil' do
          expect(authenticator.send(:read_openbao_secret_token)).to be_nil
        end
      end

      context 'when the file path resolves outside allowed paths' do
        # A real file in /tmp resolves to a path outside Rails root - no Pathname stub needed
        let(:outside_file) { Tempfile.new('openbao_outside') } # created in system /tmp

        before do
          outside_file.write('token')
          outside_file.flush

          openbao_config = Gitlab.config.openbao.to_h
          openbao_config['authentication_token_secret_file_path'] = outside_file.path
          allow(Gitlab.config).to receive(:openbao).and_return(openbao_config)
        end

        after do
          outside_file.close!
        end

        it 'returns nil' do
          expect(authenticator.send(:read_openbao_secret_token)).to be_nil
        end
      end

      context 'when the path exists but is not a file' do
        before do
          allow(File).to receive(:file?).and_call_original
          allow(File).to receive(:file?).with(Pathname.new(token_file.path).realpath.to_s).and_return(false)
        end

        it 'returns nil' do
          expect(authenticator.send(:read_openbao_secret_token)).to be_nil
        end
      end

      context 'when the file does not exist (ENOENT)' do
        before do
          openbao_config = Gitlab.config.openbao.to_h
          openbao_config['authentication_token_secret_file_path'] = '/nonexistent/token.txt'
          allow(Gitlab.config).to receive(:openbao).and_return(openbao_config)
        end

        it 'tracks the error and returns nil' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(instance_of(Errno::ENOENT))

          expect(authenticator.send(:read_openbao_secret_token)).to be_nil
        end
      end

      context 'when the file is not accessible (EACCES)' do
        before do
          allow(File).to receive(:read).and_call_original
          allow(File).to receive(:read).with(Pathname.new(token_file.path).realpath.to_s).and_raise(Errno::EACCES)
        end

        it 'tracks the error and returns nil' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(instance_of(Errno::EACCES))

          expect(authenticator.send(:read_openbao_secret_token)).to be_nil
        end
      end

      context 'when the token file is empty' do
        before do
          token_file.truncate(0)
          token_file.flush
        end

        it 'returns nil' do
          expect(authenticator.send(:read_openbao_secret_token)).to be_nil
        end
      end

      context 'when not in development or test environment' do
        before do
          allow(Rails.env).to receive_messages(development?: false, test?: false)
        end

        it 'includes /etc/gitlab/ in allowed paths' do
          # token_file is in Rails.root/tmp so still passes the allowed path check
          expect(authenticator.send(:read_openbao_secret_token)).to eq('super_secret_token')
        end
      end
    end

    describe 'CI Job Router' do
      before do
        allow(request).to receive_messages(path: '/api/v4/internal/ci/job_router/execute', env: {})
      end

      it 'calls verify_kas' do
        expect(::Gitlab::Kas).to receive(:verify_api_request).and_return(true)

        expect(authenticator.verify!).to be_truthy
      end
    end

    describe 'Error Tracking Service' do
      before do
        allow(request).to receive_messages(path: '/api/v4/internal/error_tracking/events',
          env: { 'HTTP_GITLAB_ERROR_TRACKING_TOKEN' => 'track123' })
      end

      context 'when token is provided in headers' do
        it 'validates against stored secret' do
          expect(Gitlab::CurrentSettings).to receive(:error_tracking_access_token).and_return('track123')

          expect(authenticator.verify!).to be_truthy
        end
      end

      context 'when header token does not match secret' do
        it 'returns false' do
          expect(Gitlab::CurrentSettings).to receive(:error_tracking_access_token).and_return('different_token')

          expect(authenticator.verify!).to be_falsey
        end
      end

      context 'when token is in query parameters' do
        before do
          allow(request).to receive_messages(path: '/api/v4/internal/error_tracking/events', env: {})
          allow(request).to receive(:GET).and_return({ 'error_tracking_token' => 'track123' })
        end

        it 'validates from query params' do
          expect(Gitlab::CurrentSettings).to receive(:error_tracking_access_token).and_return('track123')

          expect(authenticator.verify!).to be_truthy
        end
      end

      context 'when no token is provided' do
        before do
          allow(request).to receive_messages(path: '/api/v4/internal/error_tracking/events', env: {})
          allow(request).to receive(:GET).and_return({})
        end

        it 'returns false' do
          expect(authenticator.verify!).to be_falsey
        end
      end

      context 'when secret is nil' do
        before do
          allow(request).to receive_messages(
            path: '/api/v4/internal/error_tracking/events',
            env: { 'HTTP_GITLAB_ERROR_TRACKING_TOKEN' => 'track123' }
          )
        end

        it 'returns false' do
          expect(Gitlab::CurrentSettings).to receive(:error_tracking_access_token).and_return(nil)

          expect(authenticator.verify!).to be_falsey
        end
      end

      context 'when verification raises StandardError' do
        it 'catches error and returns false' do
          expect(Gitlab::CurrentSettings).to receive(:error_tracking_access_token).and_raise(StandardError)
          expect(Gitlab::AppLogger).to receive(:info)

          expect(authenticator.verify!).to be_falsey
        end
      end
    end

    describe 'Mail Room' do
      before do
        allow(request).to receive_messages(path: '/api/v4/internal/mail_room/inbox', env: {})
      end

      context 'when authentication succeeds' do
        it 'calls verify_mailroom' do
          expect(::Gitlab::MailRoom::Authenticator).to receive(:verify_api_request).and_return(true)

          expect(authenticator.verify!).to be_truthy
        end
      end

      context 'when mailbox type is missing' do
        before do
          allow(request).to receive(:path).and_return('/api/v4/internal/mail_room/')
        end

        it 'returns false' do
          expect(authenticator.verify!).to be_falsey
        end
      end

      context 'when verification raises StandardError' do
        it 'catches error and returns false' do
          expect(::Gitlab::MailRoom::Authenticator).to receive(:verify_api_request).and_raise(StandardError)
          expect(Gitlab::AppLogger).to receive(:info)

          expect(authenticator.verify!).to be_falsey
        end
      end
    end

    describe 'DAST Site Validations' do
      before do
        allow(request).to receive_messages(path: '/api/v4/internal/dast/site_validations/validate', env: {})
      end

      context 'when no job token is present' do
        it 'returns false' do
          expect(authenticator.verify!).to be_falsey
        end
      end

      context 'when job token is present' do
        before do
          allow(request).to receive(:env).and_return({ 'HTTP_JOB_TOKEN' => 'job_token_123' })
        end

        context 'with valid token' do
          before do
            allow(::Ci::AuthJobFinder).to receive(:new).and_return(
              instance_double(::Ci::AuthJobFinder, execute!: true)
            )
          end

          it 'returns true' do
            expect(authenticator.verify!).to be true
          end
        end

        context 'with invalid token' do
          before do
            allow(::Ci::AuthJobFinder).to receive(:new).and_return(
              instance_double(::Ci::AuthJobFinder, execute!: nil)
            )
          end

          it 'returns false' do
            expect(authenticator.verify!).to be false
          end
        end

        context 'when verification raises StandardError' do
          before do
            allow(::Ci::AuthJobFinder).to receive(:new).and_return(
              instance_double(::Ci::AuthJobFinder, execute!: nil)
            )
          end

          it 'catches error and returns false' do
            expect(::Ci::AuthJobFinder).to receive(:new).and_raise(StandardError)
            expect(Gitlab::AppLogger).to receive(:info)

            expect(authenticator.verify!).to be_falsey
          end
        end
      end
    end

    describe 'Coverage (Coverband)' do
      let(:deeply_quoted_json) { "{\"a\":\"#{'\\\"' * 100}\"}" }
      let(:rack_input) { StringIO.new(deeply_quoted_json) }

      before do
        allow(request).to receive_messages(
          path: '/api/v4/internal/coverage',
          env: { 'rack.input' => rack_input }
        )
      end

      it 'returns true' do
        expect(authenticator.verify!).to be true
      end

      it 'replaces rack.input with an empty JSON body' do
        authenticator.verify!

        new_input = request.env['rack.input']
        expect(new_input.read).to eq('{}')
      end
    end
  end

  describe 'header normalization' do
    subject(:authenticator) { described_class.new(request) }

    before do
      allow(request).to receive(:path).and_return('/api/v4/internal/test')
    end

    it 'converts HTTP_ prefixed environment variables to headers' do
      env = {
        'HTTP_CUSTOM_HEADER' => 'value1',
        'HTTP_ANOTHER_HEADER' => 'value2',
        'OTHER_VAR' => 'ignored'
      }

      allow(request).to receive(:env).and_return(env)

      headers = authenticator.instance_variable_get(:@headers)

      expect(headers['Custom-Header']).to eq('value1')
      expect(headers['Another-Header']).to eq('value2')
      expect(headers['Other-Var']).to be_nil
    end

    it 'handles header name capitalization correctly' do
      env = {
        'HTTP_GITLAB_SHELL_SECRET_TOKEN' => 'shell_secret',
        'HTTP_X_FORWARDED_FOR' => '1.2.3.4'
      }

      allow(request).to receive(:env).and_return(env)

      headers = authenticator.instance_variable_get(:@headers)

      expect(headers['Gitlab-Shell-Secret-Token']).to eq('shell_secret')
      expect(headers['X-Forwarded-For']).to eq('1.2.3.4')
    end

    it 'includes CONTENT_TYPE and CONTENT_LENGTH headers' do
      env = {
        'CONTENT_TYPE' => 'application/json',
        'CONTENT_LENGTH' => '512'
      }

      allow(request).to receive(:env).and_return(env)

      headers = authenticator.instance_variable_get(:@headers)

      expect(headers['Content-Type']).to eq('application/json')
      expect(headers['Content-Length']).to eq('512')
    end
  end

  describe 'route matching' do
    subject(:authenticator) { described_class.new(request) }

    before do
      allow(request).to receive(:env).and_return({})
    end

    context 'with various path patterns' do
      {
        '/api/v4/internal/gitlab_subscriptions/list' => :verify_subscriptions,
        '/api/v4/internal/kubernetes/agent_config' => :verify_kas,
        '/api/v4/internal/search/zoekt/search' => :verify_shell,
        '/api/v4/internal/workhorse/authorize' => :verify_workhorse,
        '/api/v4/internal/dast/site/validate' => :verify_dast_job,
        '/api/v4/internal/secrets_manager/token' => :verify_openbao,
        '/api/v4/internal/error_tracking/events' => :verify_error_tracking,
        '/api/v4/internal/mail_room/imap' => :verify_mailroom,
        '/api/v4/internal/allowed' => :verify_shell,
        '/api/v4/internal/lfs_authenticate' => :verify_shell,
        '/api/v4/internal/two_factor' => :verify_shell,
        '/api/v4/internal/personal_access_token' => :verify_shell,
        '/api/v4/internal/pre_receive' => :verify_shell,
        '/api/v4/internal/post_receive' => :verify_shell,
        '/api/v4/internal/ci/job_router/execute' => :verify_kas,
        '/api/v4/internal/shellhorse/test' => :verify_shell_or_workhorse,
        '/api/v4/internal/observability/logs' => :verify_workhorse,
        '/api/v4/internal/coverage' => :verify_coverage
      }.each do |path, verifier|
        context "with path #{path}" do
          before do
            allow(request).to receive(:path).and_return(path)
          end

          it "routes to #{verifier}" do
            allow(authenticator).to receive(verifier).and_return(true)

            expect(authenticator).to receive(verifier)
            authenticator.verify!
          end
        end
      end
    end
  end
end
