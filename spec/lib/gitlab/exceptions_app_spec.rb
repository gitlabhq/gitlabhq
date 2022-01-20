# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ExceptionsApp, type: :request do
  describe '.call' do
    let(:exceptions_app) { described_class.new(Rails.public_path) }
    let(:app) { ActionDispatch::ShowExceptions.new(error_raiser, exceptions_app) }

    before do
      @app = app
    end

    context 'for a 500 error' do
      let(:error_raiser) { proc { raise 'an unhandled error' } }

      context 'for an HTML request' do
        it 'fills in the request ID' do
          get '/', env: { 'action_dispatch.request_id' => 'foo' }

          expect(response).to have_gitlab_http_status(:internal_server_error)
          expect(response).to have_header('X-Gitlab-Custom-Error')
          expect(response.body).to include('Request ID: <code>foo</code>')
        end

        it 'HTML-escapes the request ID' do
          get '/', env: { 'action_dispatch.request_id' => '<b>foo</b>' }

          expect(response).to have_gitlab_http_status(:internal_server_error)
          expect(response).to have_header('X-Gitlab-Custom-Error')
          expect(response.body).to include('Request ID: <code>&lt;b&gt;foo&lt;/b&gt;</code>')
        end

        it 'returns an empty 500 when the 500.html page cannot be found' do
          allow(File).to receive(:exist?).and_return(false)

          get '/', env: { 'action_dispatch.request_id' => 'foo' }

          expect(response).to have_gitlab_http_status(:internal_server_error)
          expect(response).not_to have_header('X-Gitlab-Custom-Error')
          expect(response.body).to be_empty
        end
      end

      context 'for a JSON request' do
        it 'does not include the request ID' do
          get '/', env: { 'action_dispatch.request_id' => 'foo' }, as: :json

          expect(response).to have_gitlab_http_status(:internal_server_error)
          expect(response).not_to have_header('X-Gitlab-Custom-Error')
          expect(response.body).not_to include('foo')
        end
      end
    end

    context 'for a 404 error' do
      let(:error_raiser) { proc { raise AbstractController::ActionNotFound } }

      it 'returns a 404 response that does not include the request ID' do
        get '/', env: { 'action_dispatch.request_id' => 'foo' }

        expect(response).to have_gitlab_http_status(:not_found)
        expect(response).not_to have_header('X-Gitlab-Custom-Error')
        expect(response.body).not_to include('foo')
      end
    end
  end
end
