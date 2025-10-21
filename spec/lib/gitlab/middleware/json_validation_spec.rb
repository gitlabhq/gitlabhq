# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::JsonValidation, feature_category: :shared do
  let(:app) { double(:app) } # rubocop:disable RSpec/VerifiedDoubles -- stubbed app
  let(:middleware) { described_class.new(app, options) }
  let(:options) { {} }

  let(:env) do
    {
      'REQUEST_METHOD' => 'POST',
      'CONTENT_TYPE' => content_type,
      'PATH_INFO' => '/api/v4/projects',
      'rack.input' => StringIO.new(body)
    }
  end

  let(:content_type) { 'application/json' }
  let(:body) { '{"key": "value"}' }

  before do
    allow(app).to receive(:call).and_return([200, {}, ['OK']])
  end

  describe '#initialize' do
    it 'merges custom default_limits with defaults' do
      custom_options = { default_limits: { max_depth: 10, mode: :logging, max_json_size_bytes: 30.megabytes } }
      middleware = described_class.new(app, custom_options)

      expect(middleware.instance_variable_get(:@default_limits)).to include(
        max_depth: 10,
        max_array_size: 50000,
        max_hash_size: 50000,
        max_total_elements: 100000,
        max_json_size_bytes: 30.megabytes,
        mode: :logging
      )
    end

    it 'uses DEFAULT_LIMITS when no custom default_limits provided' do
      middleware = described_class.new(app, {})

      expect(middleware.instance_variable_get(:@default_limits)).to eq(described_class::DEFAULT_LIMITS)
    end

    it 'builds route configs from route_limits option and default route limits' do
      route_limits = [
        {
          regex: %r{\A/api/v4/projects/\d+/issues\z},
          methods: %i[post],
          limits: { max_depth: 5, mode: :enforced }
        },
        {
          regex: %r{\A/api/v4/users\z},
          methods: %i[post],
          limits: { max_array_size: 100, mode: :logging }
        }
      ]
      custom_options = { route_limits: route_limits }
      middleware = described_class.new(app, custom_options)

      route_config_map = middleware.instance_variable_get(:@route_config_map)
      # Should include default route configs (7) plus custom route limits (2)
      expect(route_config_map.size).to eq(9)
      expect(route_config_map.first).to be_a(Hash)
      expect(route_config_map.first).to have_key(:regex)
      expect(route_config_map.first).to have_key(:methods)
      expect(route_config_map.first).to have_key(:limits)
    end

    it 'allows custom route limits to override default route configs' do
      # Override the Terraform state config
      route_limits = [
        {
          regex: described_class::TERRAFORM_STATE_PATH,
          methods: %i[post],
          limits: { max_depth: 5, mode: :enforced }
        }
      ]
      custom_options = { route_limits: route_limits }
      middleware = described_class.new(app, custom_options)

      route_config_map = middleware.instance_variable_get(:@route_config_map)
      terraform_config = route_config_map.find { |config| config[:regex] == described_class::TERRAFORM_STATE_PATH }

      expect(terraform_config[:limits][:mode]).to eq(:enforced)
      expect(terraform_config[:limits][:max_depth]).to eq(5)
    end
  end

  describe '#call' do
    context 'when global validation mode is disabled' do
      before do
        stub_env('GITLAB_JSON_GLOBAL_VALIDATION_MODE', 'disabled')
      end

      it 'passes through without validation regardless of default limits' do
        expect(app).to receive(:call).with(env)
        expect(::Gitlab::Json::StreamValidator).not_to receive(:new)

        middleware.call(env)
      end
    end

    context 'when global validation mode is logging' do
      before do
        stub_env('GITLAB_JSON_GLOBAL_VALIDATION_MODE', 'logging')
      end

      let(:options) { { default_limits: { max_depth: 1, mode: :enforced } } }
      let(:body) { '{"a": {"b": "nested"}}' }

      it 'forces logging mode even when route is configured for enforced mode' do
        expect(Gitlab::AppLogger).to receive(:warn).with(hash_excluding(:status))
        expect(app).to receive(:call).with(env)

        result = middleware.call(env)
        expect(result).to eq([200, {}, ['OK']])
      end
    end

    context 'when mode is disabled' do
      let(:options) { { default_limits: { mode: :disabled } } }

      it 'passes through without validation' do
        expect(app).to receive(:call).with(env)
        expect(::Gitlab::Json::StreamValidator).not_to receive(:new)

        middleware.call(env)
      end
    end

    context 'when request is not JSON' do
      let(:content_type) { 'text/html' }

      it 'passes through without validation' do
        expect(app).to receive(:call).with(env)
        expect(::Gitlab::Json::StreamValidator).not_to receive(:new)

        middleware.call(env)
      end
    end

    context 'with different JSON content types' do
      shared_examples 'validates JSON content type' do
        it 'validates the request' do
          expect(::Oj).to receive(:sc_parse).with(an_instance_of(Gitlab::Json::StreamValidator), body)
          expect(app).to receive(:call).with(env)

          middleware.call(env)
        end
      end

      context 'with application/json' do
        let(:content_type) { 'application/json' }

        it_behaves_like 'validates JSON content type'
      end

      context 'with application/json; charset=utf-8' do
        let(:content_type) { 'application/json; charset=utf-8' }

        it_behaves_like 'validates JSON content type'
      end

      context 'with application/vnd.git-lfs+json' do
        let(:content_type) { 'application/vnd.git-lfs+json' }

        it_behaves_like 'validates JSON content type'
      end

      context 'with APPLICATION/JSON (uppercase)' do
        let(:content_type) { 'APPLICATION/JSON' }

        it_behaves_like 'validates JSON content type'
      end
    end

    context 'with empty body' do
      let(:body) { '' }

      it 'passes through without validation' do
        expect(app).to receive(:call).with(env)
        expect(::Oj).not_to receive(:sc_parse)

        middleware.call(env)
      end
    end

    context 'with valid JSON' do
      let(:body) { '{"name": "test", "items": [1, 2, 3]}' }

      it 'validates and passes through' do
        expect(app).to receive(:call).with(env)

        result = middleware.call(env)
        expect(result).to eq([200, {}, ['OK']])
      end

      it 'rewinds the request body after reading' do
        rack_input = StringIO.new(body)
        env['rack.input'] = rack_input

        expect(rack_input).to receive(:read).and_call_original
        expect(rack_input).to receive(:rewind).and_call_original

        middleware.call(env)
      end
    end

    context 'with invalid JSON syntax' do
      let(:body) { '{"invalid": json}' }

      it 'allows invalid JSON to pass through' do
        expect(app).to receive(:call).with(env)

        result = middleware.call(env)
        expect(result).to eq([200, {}, ['OK']])
      end
    end

    context 'when JSON body is too large' do
      let(:options) { { default_limits: { max_json_size_bytes: 10 } } }
      let(:body) { '{"key": "very long value"}' }

      context 'in enforced mode' do
        let(:options) { { default_limits: { max_json_size_bytes: 10, mode: :enforced } } }

        it 'returns 400 error' do
          result = middleware.call(env)

          expect(result[0]).to eq(400)
          expect(result[1]).to eq({ 'Content-Type' => 'application/json' })

          response_body = Gitlab::Json.parse(result[2].first)
          expect(response_body['error']).to include('JSON body too large')
        end

        it 'logs the error' do
          expect(Gitlab::AppLogger).to receive(:warn).with(
            hash_including(
              class_name: 'Gitlab::Middleware::JsonValidation',
              path: '/api/v4/projects',
              message: a_string_including('JSON body too large'),
              status: 400
            )
          )

          middleware.call(env)
        end
      end

      context 'in logging mode' do
        let(:options) { { default_limits: { max_json_size_bytes: 10, mode: :logging } } }

        it 'logs error but allows request to continue' do
          expect(Gitlab::AppLogger).to receive(:warn).with(
            hash_excluding(:status)
          )
          expect(app).to receive(:call).with(env)

          result = middleware.call(env)
          expect(result).to eq([200, {}, ['OK']])
        end
      end
    end

    context 'when JSON exceeds depth limit' do
      let(:options) { { default_limits: { max_depth: 2, mode: :enforced } } }
      let(:body) { '{"a": {"b": {"c": "too deep"}}}' }

      it 'returns 400 error with depth message' do
        result = middleware.call(env)

        expect(result[0]).to eq(400)
        response_body = Gitlab::Json.parse(result[2].first)
        expect(response_body['error']).to eq('Parameters nested too deeply')
      end

      it 'logs the depth limit error' do
        expect(Gitlab::AppLogger).to receive(:warn).with(
          hash_including(
            class_name: 'Gitlab::Middleware::JsonValidation',
            message: a_string_including('depth')
          )
        )

        middleware.call(env)
      end
    end

    context 'when JSON exceeds array size limit' do
      let(:options) { { default_limits: { max_array_size: 2, mode: :enforced } } }
      let(:body) { '{"items": [1, 2, 3]}' }

      it 'returns 400 error with array size message' do
        result = middleware.call(env)

        expect(result[0]).to eq(400)
        response_body = Gitlab::Json.parse(result[2].first)
        expect(response_body['error']).to eq('Array parameter too large')
      end
    end

    context 'when JSON exceeds hash size limit' do
      let(:options) { { default_limits: { max_hash_size: 2, mode: :enforced } } }
      let(:body) { '{"a": 1, "b": 2, "c": 3}' }

      it 'returns 400 error with hash size message' do
        result = middleware.call(env)

        expect(result[0]).to eq(400)
        response_body = Gitlab::Json.parse(result[2].first)
        expect(response_body['error']).to eq('Hash parameter too large')
      end

      it 'logs the hash size limit error' do
        expect(Gitlab::AppLogger).to receive(:warn).with(
          hash_including(
            class_name: 'Gitlab::Middleware::JsonValidation',
            message: a_string_including('Hash size exceeds limit')
          )
        )

        middleware.call(env)
      end
    end

    context 'when JSON exceeds total elements limit' do
      let(:options) { { default_limits: { max_total_elements: 3, mode: :enforced } } }
      let(:body) { '{"a": 1, "b": 2, "c": 3, "d": 4}' }

      it 'returns 400 error with element count message' do
        result = middleware.call(env)

        expect(result[0]).to eq(400)
        response_body = Gitlab::Json.parse(result[2].first)
        expect(response_body['error']).to eq('Too many total parameters')
      end
    end

    context 'in logging mode with validation errors' do
      let(:options) { { default_limits: { max_depth: 1, mode: :logging } } }
      let(:body) { '{"a": {"b": "nested"}}' }

      it 'logs error but continues processing' do
        expect(Gitlab::AppLogger).to receive(:warn)
        expect(app).to receive(:call).with(env)

        result = middleware.call(env)
        expect(result).to eq([200, {}, ['OK']])
      end
    end

    context 'with instrumentation' do
      let(:options) { { default_limits: { max_depth: 1, mode: :enforced } } }
      let(:body) { '{"a": {"b": "nested"}}' }

      it 'adds instrumentation data' do
        expect(::Gitlab::InstrumentationHelper).to receive(:add_instrumentation_data).with(
          hash_including(
            max_depth: 1,
            mode: :enforced,
            path: '/api/v4/projects',
            message: a_string_including('depth')
          )
        )

        middleware.call(env)
      end
    end

    context 'with default route configurations' do
      let(:options) { { default_limits: { max_depth: 1, mode: :enforced } } }
      let(:body) { '{"deeply": {"nested": {"json": "that would normally fail"}}}' }

      context 'for internal API paths' do
        let(:env) do
          {
            'REQUEST_METHOD' => 'POST',
            'CONTENT_TYPE' => content_type,
            'PATH_INFO' => '/api/v4/internal/some/endpoint',
            'rack.input' => StringIO.new(body)
          }
        end

        it 'validates internal API' do
          # Should validate but not fail due to route-specific internal API limits
          expect(::Gitlab::Json::StreamValidator).to receive(:new).and_call_original
          expect(app).to receive(:call).with(env)

          result = middleware.call(env)

          expect(result).to eq([200, {}, ['OK']])
        end
      end

      context 'for Duo Workflow paths' do
        let(:env) do
          {
            'REQUEST_METHOD' => 'POST',
            'CONTENT_TYPE' => content_type,
            'PATH_INFO' => '/api/v4/ai/duo_workflows/workflows/123',
            'rack.input' => StringIO.new(body)
          }
        end

        it 'validates Duo Workflow API' do
          # Should validate but not fail due to route-specific internal API limits

          expect(::Gitlab::Json::StreamValidator).to receive(:new).and_call_original
          expect(app).to receive(:call).with(env)

          result = middleware.call(env)

          expect(result).to eq([200, {}, ['OK']])
        end
      end
    end

    context 'with custom limits for URLs' do
      let(:options) { { default_limits: { max_depth: 1, mode: :enforced } } }
      let(:body) { '{"deeply": {"nested": {"json": "that would normally fail"}}}' }
      let(:env) do
        {
          'REQUEST_METHOD' => 'POST',
          'CONTENT_TYPE' => content_type,
          'PATH_INFO' => path_info,
          'rack.input' => StringIO.new(body)
        }
      end

      context 'with Terraform and NPM routes' do
        where(:description, :path_info) do
          [
            ['Terraform state with numeric project ID', '/api/v4/projects/123/terraform/state/prod'],
            ['Terraform state with URL-encoded project ID', '/api/v4/projects/group%2Fproject/terraform/state/staging'],
            ['NPM instance advisories bulk', '/api/v4/packages/npm/-/npm/v1/security/advisories/bulk'],
            ['NPM instance audits quick', '/api/v4/packages/npm/-/npm/v1/security/audits/quick'],
            ['NPM group advisories bulk', '/api/v4/groups/my-group/-/packages/npm/-/npm/v1/security/advisories/bulk'],
            ['NPM group audits quick', '/api/v4/groups/my-group/-/packages/npm/-/npm/v1/security/audits/quick'],
            ['NPM group with URL-encoded ID',
              '/api/v4/groups/parent%2Fchild/-/packages/npm/-/npm/v1/security/advisories/bulk'],
            ['NPM project advisories bulk', '/api/v4/projects/123/packages/npm/-/npm/v1/security/advisories/bulk'],
            ['NPM project audits quick', '/api/v4/projects/123/packages/npm/-/npm/v1/security/audits/quick'],
            ['NPM project with URL-encoded ID',
              '/api/v4/projects/group%2Fproject/packages/npm/-/npm/v1/security/audits/quick']
          ]
        end

        with_them do
          it 'validates payloads' do
            expect(::Gitlab::Json::StreamValidator).to receive(:new).and_call_original
            expect(app).to receive(:call).with(env)

            result = middleware.call(env)
            expect(result).to eq([200, {}, ['OK']])
          end
        end
      end

      context 'for collect_events endpoint' do
        let(:path_info) { '/-/collect_events' }

        it 'validates payloads' do
          expect(::Gitlab::Json::StreamValidator).to receive(:new).and_call_original
          expect(app).to receive(:call).with(env)

          result = middleware.call(env)
          expect(result).to eq([200, {}, ['OK']])
        end

        context 'for a very large body exceeding 10 megabytes' do
          let(:body) { "{\"json\" : \"#{'a' * 11_000_000}\"}" }

          it 'rejects the large payload' do
            result = middleware.call(env)
            expect(result).to eq([400, { "Content-Type" => "application/json" }, ['{"error":"JSON body too large"}']])
          end
        end
      end

      context 'with internal API routes' do
        where(:description, :path_info) do
          [
            ['Internal API endpoint', '/api/v4/internal/some/endpoint'],
            ['Internal API nested path', '/api/v4/internal/pages/domains'],
            ['Duo workflow endpoint', '/api/v4/ai/duo_workflows/workflows/123'],
            ['Duo workflow nested path', '/api/v4/ai/duo_workflows/workflows/456/execute']
          ]
        end

        with_them do
          it 'validates payloads' do
            expect(::Gitlab::Json::StreamValidator).to receive(:new).and_call_original
            expect(app).to receive(:call).with(env)

            result = middleware.call(env)
            expect(result).to eq([200, {}, ['OK']])
          end
        end
      end

      context 'when request method is not POST' do
        let(:env) do
          {
            'REQUEST_METHOD' => 'GET',
            'CONTENT_TYPE' => content_type,
            'PATH_INFO' => '/api/v4/projects/123/terraform/state/name',
            'rack.input' => StringIO.new(body)
          }
        end

        it 'does not exempt non-POST requests' do
          expect(::Gitlab::Json::StreamValidator).to receive(:new).and_call_original
          result = middleware.call(env)

          expect(result[0]).to eq(400)
          response_body = Gitlab::Json.parse(result[2].first)
          expect(response_body['error']).to eq('Parameters nested too deeply')
        end
      end

      context 'with relative URL root configured' do
        before do
          allow(Gitlab.config.gitlab).to receive(:relative_url_root).and_return('/gitlab')
        end

        let(:env) do
          {
            'REQUEST_METHOD' => 'POST',
            'CONTENT_TYPE' => content_type,
            'PATH_INFO' => '/gitlab/api/v4/projects/123/terraform/state/hello',
            'rack.input' => StringIO.new(body)
          }
        end

        it 'validates paylods with relative root' do
          expect(::Gitlab::Json::StreamValidator).to receive(:new).and_call_original
          expect(app).to receive(:call).with(env)

          result = middleware.call(env)
          expect(result).to eq([200, {}, ['OK']])
        end
      end

      context 'for non-exempt URLs' do
        let(:env) do
          {
            'REQUEST_METHOD' => 'POST',
            'CONTENT_TYPE' => content_type,
            'PATH_INFO' => '/api/v4/projects/123/issues',
            'rack.input' => StringIO.new(body)
          }
        end

        it 'applies validation normally' do
          result = middleware.call(env)

          expect(result[0]).to eq(400)
          response_body = Gitlab::Json.parse(result[2].first)
          expect(response_body['error']).to eq('Parameters nested too deeply')
        end
      end
    end

    context 'with route-specific limits' do
      let(:route_limits) do
        [
          {
            regex: %r{\A/api/v4/projects/\d+/issues\z},
            methods: %i[post],
            limits: { max_depth: 5, mode: :enforced }
          },
          {
            regex: %r{\A/api/v4/users\z},
            methods: %i[post],
            limits: { max_array_size: 2, mode: :enforced }
          },
          {
            regex: %r{\A/api/v4/groups\z},
            methods: %i[post],
            limits: { max_hash_size: 1, mode: :logging }
          }
        ]
      end

      let(:options) { { route_limits: route_limits, default_limits: { mode: :logging } } }

      context 'when path matches route-specific limits' do
        let(:env) do
          {
            'REQUEST_METHOD' => 'POST',
            'CONTENT_TYPE' => content_type,
            'PATH_INFO' => '/api/v4/projects/123/issues',
            'rack.input' => StringIO.new(body)
          }
        end

        context 'with JSON exceeding route-specific depth limit' do
          let(:body) { '{"a": {"b": {"c": {"d": {"e": {"f": "too deep"}}}}}}' }

          it 'applies route-specific limits instead of global defaults' do
            result = middleware.call(env)

            expect(result[0]).to eq(400)
            response_body = Gitlab::Json.parse(result[2].first)
            expect(response_body['error']).to eq('Parameters nested too deeply')
            expect(env[described_class::RACK_ENV_METADATA_KEY]).to be_present
          end

          it 'logs with route-specific limits' do
            expect(Gitlab::AppLogger).to receive(:warn).with(
              hash_including(
                max_depth: 5,
                mode: :enforced,
                path: '/api/v4/projects/123/issues'
              )
            )

            middleware.call(env)
          end
        end

        context 'with JSON within route-specific limits' do
          let(:body) { '{"a": {"b": {"c": "within limit"}}}' }

          it 'allows request to pass through' do
            expect(app).to receive(:call).with(env)

            result = middleware.call(env)
            expect(result).to eq([200, {}, ['OK']])
          end
        end
      end

      context 'when path matches array size route limit' do
        let(:env) do
          {
            'REQUEST_METHOD' => 'POST',
            'CONTENT_TYPE' => content_type,
            'PATH_INFO' => '/api/v4/users',
            'rack.input' => StringIO.new(body)
          }
        end

        let(:body) { '{"items": [1, 2, 3]}' }

        it 'applies route-specific array size limit' do
          result = middleware.call(env)

          expect(result[0]).to eq(400)
          response_body = Gitlab::Json.parse(result[2].first)
          expect(response_body['error']).to eq('Array parameter too large')
        end
      end

      context 'when path matches logging mode route limit' do
        let(:env) do
          {
            'REQUEST_METHOD' => 'POST',
            'CONTENT_TYPE' => content_type,
            'PATH_INFO' => '/api/v4/groups',
            'rack.input' => StringIO.new(body)
          }
        end

        let(:body) { '{"a": 1, "b": 2}' }

        it 'uses route-specific logging mode instead of global disabled mode' do
          expect(Gitlab::AppLogger).to receive(:warn).with(
            hash_including(
              max_hash_size: 1,
              mode: :logging,
              path: '/api/v4/groups'
            )
          )
          expect(app).to receive(:call).with(env)

          result = middleware.call(env)
          expect(result).to eq([200, {}, ['OK']])
        end
      end

      context 'when path does not match any route-specific limits' do
        let(:env) do
          {
            'REQUEST_METHOD' => 'POST',
            'CONTENT_TYPE' => content_type,
            'PATH_INFO' => '/api/v4/other/endpoint',
            'rack.input' => StringIO.new(body)
          }
        end

        let(:body) { '{"deeply": {"nested": {"json": "content"}}}' }

        it 'uses global defaults (logging mode)' do
          expect(app).to receive(:call).with(env)
          expect(::Gitlab::Json::StreamValidator).to receive(:new).and_call_original

          result = middleware.call(env)
          expect(result).to eq([200, {}, ['OK']])
        end
      end

      context 'with relative URL root' do
        before do
          allow(Gitlab.config.gitlab).to receive(:relative_url_root).and_return('/gitlab')
        end

        let(:env) do
          {
            'REQUEST_METHOD' => 'POST',
            'CONTENT_TYPE' => content_type,
            'PATH_INFO' => '/gitlab/api/v4/projects/123/issues',
            'rack.input' => StringIO.new(body)
          }
        end

        let(:body) { '{"a": {"b": {"c": {"d": {"e": {"f": "too deep"}}}}}}' }

        it 'matches route patterns after stripping relative URL root' do
          result = middleware.call(env)

          expect(result[0]).to eq(400)
          response_body = Gitlab::Json.parse(result[2].first)
          expect(response_body['error']).to eq('Parameters nested too deeply')
        end
      end
    end

    context 'with different HTTP methods' do
      let(:options) { { default_limits: { max_depth: 1, mode: :enforced } } }
      let(:body) { '{"a": {"b": "nested"}}' }

      %w[GET POST PUT PATCH DELETE].each do |method|
        context "with #{method} request" do
          let(:env) do
            {
              'REQUEST_METHOD' => method,
              'CONTENT_TYPE' => content_type,
              'PATH_INFO' => '/api/v4/projects',
              'rack.input' => StringIO.new(body)
            }
          end

          it 'validates JSON for all HTTP methods by default' do
            result = middleware.call(env)
            expect(result[0]).to eq(400)
          end
        end
      end

      context 'with method-specific route configuration' do
        let(:route_limits) do
          [
            {
              regex: %r{\A/api/v4/custom/test\z},
              methods: %i[post put],
              limits: { mode: :disabled }
            }
          ]
        end

        let(:options) { { route_limits: route_limits, default_limits: { max_depth: 1, mode: :enforced } } }

        context 'with configured method (POST)' do
          let(:env) do
            {
              'REQUEST_METHOD' => 'POST',
              'CONTENT_TYPE' => content_type,
              'PATH_INFO' => '/api/v4/custom/test',
              'rack.input' => StringIO.new(body)
            }
          end

          it 'uses route-specific configuration' do
            expect(app).to receive(:call).with(env)
            expect(::Gitlab::Json::StreamValidator).not_to receive(:new)
            result = middleware.call(env)
            expect(result).to eq([200, {}, ['OK']])
          end
        end

        context 'with non-configured method (GET)' do
          let(:env) do
            {
              'REQUEST_METHOD' => 'GET',
              'CONTENT_TYPE' => content_type,
              'PATH_INFO' => '/api/v4/custom/test',
              'rack.input' => StringIO.new(body)
            }
          end

          it 'uses default configuration' do
            result = middleware.call(env)
            expect(result[0]).to eq(400)
          end
        end
      end
    end

    context 'with encoding errors' do
      let(:body) { "\xFF\xFE{\"key\": \"value\"}" } # Invalid UTF-8

      it 'allows requests with encoding errors to pass through' do
        expect(app).to receive(:call).with(env)
        result = middleware.call(env)
        expect(result).to eq([200, {}, ['OK']])
      end
    end
  end
end
