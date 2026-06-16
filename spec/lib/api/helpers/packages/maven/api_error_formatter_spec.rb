# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::Packages::Maven::ApiErrorFormatter, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  let(:base_helper_module) do
    Module.new do
      attr_reader :fallback_args, :env_status_code, :error_args

      def render_structured_api_error!(hash, status)
        @fallback_args = { hash: hash, status: status }
      end

      def set_status_code_in_env(status_code)
        @env_status_code = status_code
      end

      def error!(body, status_code, headers)
        @error_args = { body: body, status_code: status_code, headers: headers }
      end

      def header
        @header ||= {}
      end
    end
  end

  let(:helper_class) do
    base = base_helper_module
    Class.new do
      include base
      include API::Helpers::Packages::Maven::ApiErrorFormatter
    end
  end

  let(:helper) { helper_class.new }

  describe '#render_structured_api_error!' do
    context 'with a 4xx error response' do
      # rubocop:disable Layout/LineLength -- table alignment for readability
      where(:message, :status, :expected_detail) do
        '403 Forbidden - Package protected.'              | :forbidden            | 'Package protected.'
        '400 Bad request - File is too large'             | :bad_request          | 'File is too large'
        '401 Unauthorized - Invalid token'                | :unauthorized         | 'Invalid token'
        '404 Package Not Found'                           | :not_found            | '404 Package Not Found'
        '404 Group Not Found'                             | :not_found            | '404 Group Not Found'
        '404 Project Not Found'                           | :not_found            | '404 Project Not Found'
        '404 File not found on any upstream Not Found'    | :not_found            | '404 File not found on any upstream Not Found'
        '404 Not Found'                                   | :not_found            | '404 Not Found'
        '403 Forbidden'                                   | :forbidden            | '403 Forbidden'
        '401 Unauthorized'                                | :unauthorized         | '401 Unauthorized'
        '409 Conflict'                                    | :conflict             | '409 Conflict'
        '422 Unprocessable Entity'                        | :unprocessable_entity | '422 Unprocessable Entity'
        'Validation failed: Name is invalid'              | :bad_request          | 'Validation failed: Name is invalid'
        nil                                               | :bad_request          | nil
        ''                                                | :bad_request          | nil
      end
      # rubocop:enable Layout/LineLength

      with_them do
        it 'renders an RFC 9457 problem details response', :aggregate_failures do
          helper.render_structured_api_error!({ 'message' => message }, status)

          status_code = Rack::Utils.status_code(status)
          expected_body = {
            'type' => 'about:blank',
            'status' => status_code,
            'title' => Rack::Utils::HTTP_STATUS_CODES[status_code]
          }

          if expected_detail
            expected_body['detail'] = expected_detail
            expected_body['error'] = expected_detail
          end

          expect(helper.error_args[:body]).to eq(expected_body)
          expect(helper.error_args[:status_code]).to eq(status_code)
          expect(helper.error_args[:headers]).to include('Content-Type' => 'application/problem+json')
          expect(helper.env_status_code).to eq(status_code)
          expect(helper.fallback_args).to be_nil
        end
      end
    end

    context 'when message is a Hash (e.g. API rate limit too_many_requests!)' do
      before do
        stub_feature_flags(maven_problem_details_errors: true)
      end

      it 'renders RFC 9457 problem details using the nested error string', :aggregate_failures do
        error_text = 'This endpoint has been requested too many times. Try again later.'
        helper.render_structured_api_error!(
          { 'message' => { error: error_text } },
          :too_many_requests
        )

        status_code = 429
        expect(helper.error_args[:body]).to eq(
          'type' => 'about:blank',
          'status' => status_code,
          'title' => Rack::Utils::HTTP_STATUS_CODES[status_code],
          'detail' => error_text,
          'error' => error_text
        )
        expect(helper.error_args[:status_code]).to eq(status_code)
        expect(helper.error_args[:headers]).to include('Content-Type' => 'application/problem+json')
        expect(helper.env_status_code).to eq(status_code)
        expect(helper.fallback_args).to be_nil
      end
    end

    context 'with a 5xx error response' do
      it 'renders an RFC 9457 problem details response with a detail', :aggregate_failures do
        helper.render_structured_api_error!({ 'message' => 'something went wrong' }, :internal_server_error)

        expect(helper.error_args[:body]).to eq(
          'type' => 'about:blank',
          'status' => 500,
          'title' => Rack::Utils::HTTP_STATUS_CODES[500],
          'detail' => 'something went wrong',
          'error' => 'something went wrong'
        )
        expect(helper.error_args[:status_code]).to eq(500)
        expect(helper.error_args[:headers]).to include('Content-Type' => 'application/problem+json')
        expect(helper.env_status_code).to eq(500)
        expect(helper.fallback_args).to be_nil
      end

      it 'omits the detail when the message is blank', :aggregate_failures do
        helper.render_structured_api_error!({ 'message' => nil }, :internal_server_error)

        expect(helper.error_args[:body]).to eq(
          'type' => 'about:blank',
          'status' => 500,
          'title' => Rack::Utils::HTTP_STATUS_CODES[500]
        )
        expect(helper.error_args[:body]).not_to have_key('detail')
      end
    end

    context 'with a non-error status' do
      it 'falls back to the standard error renderer', :aggregate_failures do
        helper.render_structured_api_error!({ 'message' => 'noop' }, :ok)

        expect(helper.fallback_args).to eq(hash: { 'message' => 'noop', 'error' => 'noop' }, status: :ok)
        expect(helper.error_args).to be_nil
        expect(helper.env_status_code).to be_nil
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(maven_problem_details_errors: false)
      end

      it 'falls back to the standard error renderer for 4xx responses', :aggregate_failures do
        helper.render_structured_api_error!({ 'message' => '403 Forbidden' }, :forbidden)

        expect(helper.fallback_args).to eq(
          hash: { 'message' => '403 Forbidden', 'error' => '403 Forbidden' },
          status: :forbidden
        )
        expect(helper.error_args).to be_nil
      end

      it 'falls back to the standard error renderer for 5xx responses', :aggregate_failures do
        helper.render_structured_api_error!({ 'message' => 'oops' }, :internal_server_error)

        expect(helper.fallback_args).to eq(
          hash: { 'message' => 'oops', 'error' => 'oops' },
          status: :internal_server_error
        )
        expect(helper.error_args).to be_nil
      end

      it 'does not set error from message when message is blank', :aggregate_failures do
        helper.render_structured_api_error!({ 'message' => nil }, :forbidden)

        expect(helper.fallback_args).to eq(
          hash: { 'message' => nil },
          status: :forbidden
        )
        expect(helper.error_args).to be_nil
      end

      it 'does not overwrite an existing top-level error key', :aggregate_failures do
        helper.render_structured_api_error!(
          { 'message' => 'msg', 'error' => 'existing' },
          :forbidden
        )

        expect(helper.fallback_args).to eq(
          hash: { 'message' => 'msg', 'error' => 'existing' },
          status: :forbidden
        )
        expect(helper.error_args).to be_nil
      end
    end
  end
end
