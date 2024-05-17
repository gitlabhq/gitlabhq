# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Middleware::PathTraversalCheck, feature_category: :shared do
  using RSpec::Parameterized::TableSyntax

  let(:fake_response_status) { 200 }
  let(:fake_response) { [fake_response_status, { 'Content-Type' => 'text/plain' }, ['OK']] }
  let(:fake_app) { ->(_) { fake_response } }
  let(:middleware) { described_class.new(fake_app) }

  describe '#call' do
    let(:fullpath) { ::Rack::Request.new(env).fullpath }
    let(:decoded_fullpath) { CGI.unescape(fullpath) }
    let(:graphql_query) do
      <<~QUERY
        {
          currentUser {
            username
          }
        }
      QUERY
    end

    let(:env) do
      Rack::MockRequest.env_for(
        path,
        method: method,
        params: query_params
      )
    end

    subject { middleware.call(env) }

    shared_examples 'no issue' do
      it 'does not log anything' do
        expect(::Gitlab::PathTraversal)
          .to receive(:path_traversal?)
                .with(decoded_fullpath, match_new_line: false)
                .and_call_original
        expect(::Gitlab::AppLogger).not_to receive(:warn)
        expect(subject).to eq(fake_response)
      end
    end

    shared_examples 'excluded path' do
      it 'does not log anything' do
        expect(::Gitlab::PathTraversal).not_to receive(:path_traversal?)
        expect(::Gitlab::AppLogger).not_to receive(:warn)

        expect(subject).to eq(fake_response)
      end
    end

    shared_examples 'path traversal' do
      it 'logs the problem' do
        expect(::Gitlab::PathTraversal)
          .to receive(:path_traversal?)
                .with(decoded_fullpath, match_new_line: false)
                .and_call_original
        expect(::Gitlab::AppLogger)
          .to receive(:warn)
                .with({
                  class_name: described_class.name,
                  message: described_class::PATH_TRAVERSAL_MESSAGE,
                  fullpath: fullpath,
                  method: method.upcase,
                  status: fake_response_status
                }).and_call_original

        expect(subject).to eq(fake_response)
      end
    end

    # we use Rack request.full_path, this will dump the accessed path and
    # the query string. The query string is only for GETs requests.
    # Hence different expectation (when params are set) for GETs and
    # the other methods (see below)
    context 'when using get' do
      let(:method) { 'get' }

      where(:path, :query_params, :shared_example_name) do
        '/foo/bar'            | {}                                   | 'no issue'
        '/foo/../bar'         | {}                                   | 'path traversal'
        '/foo%2Fbar'          | {}                                   | 'no issue'
        '/foo%2F..%2Fbar'     | {}                                   | 'path traversal'
        '/foo%252F..%252Fbar' | {}                                   | 'no issue'

        '/foo/bar'            | { x: 'foo' }                         | 'no issue'
        '/foo/bar'            | { x: 'foo/../bar' }                  | 'path traversal'
        '/foo/bar'            | { x: 'foo%2Fbar' }                   | 'no issue'
        '/foo/bar'            | { x: 'foo%2F..%2Fbar' }              | 'no issue'
        '/foo/bar'            | { x: 'foo%252F..%252Fbar' }          | 'no issue'
        '/foo%2F..%2Fbar'     | { x: 'foo%252F..%252Fbar' }          | 'path traversal'

        '/api/graphql'        | { query: CGI.escape(graphql_query) } | 'no issue'
      end

      with_them do
        it_behaves_like params[:shared_example_name]
      end

      described_class::EXCLUDED_QUERY_PARAM_NAMES.each do |param_name|
        context "with the excluded query parameter #{param_name}" do
          let(:path) { '/foo/bar' }
          let(:query_params) { { param_name => 'an%2F..%2Fattempt', :x => 'test' } }
          let(:decoded_fullpath) { '/foo/bar?x=test' }

          it_behaves_like 'no issue'
        end
      end

      context 'with a issues search path' do
        let(:query_params) { {} }
        let(:decoded_fullpath) { '/project/-/issues/?sort=updated_desc&milestone_title=16.0&first_page_size=20' }
        let(:path) do
          'project/-/issues/?sort=updated_desc&milestone_title=16.0&search=Release%20%252525&first_page_size=20'
        end

        it_behaves_like 'no issue'
      end
    end

    %w[post put post delete patch].each do |http_method|
      context "when using #{http_method}" do
        let(:method) { http_method }

        where(:path, :query_params, :shared_example_name) do
          '/foo/bar'            | {}                          | 'no issue'
          '/foo/../bar'         | {}                          | 'path traversal'
          '/foo%2Fbar'          | {}                          | 'no issue'
          '/foo%2F..%2Fbar'     | {}                          | 'path traversal'
          '/foo%252F..%252Fbar' | {}                          | 'no issue'

          '/foo/bar'            | { x: 'foo' }                | 'no issue'
          '/foo/bar'            | { x: 'foo/../bar' }         | 'no issue'
          '/foo/bar'            | { x: 'foo%2Fbar' }          | 'no issue'
          '/foo/bar'            | { x: 'foo%2F..%2Fbar' }     | 'no issue'
          '/foo/bar'            | { x: 'foo%252F..%252Fbar' } | 'no issue'
          '/foo%2F..%2Fbar'     | { x: 'foo%252F..%252Fbar' } | 'path traversal'
        end

        with_them do
          it_behaves_like params[:shared_example_name]
        end
      end
    end

    context 'with check_path_traversal_middleware disabled' do
      before do
        stub_feature_flags(check_path_traversal_middleware: false)
      end

      where(:path, :query_params) do
        '/foo/bar'            | {}
        '/foo/../bar'         | {}
        '/foo%2Fbar'          | {}
        '/foo%2F..%2Fbar'     | {}
        '/foo%252F..%252Fbar' | {}
        '/foo/bar'            | { x: 'foo' }
        '/foo/bar'            | { x: 'foo/../bar' }
        '/foo/bar'            | { x: 'foo%2Fbar' }
        '/foo/bar'            | { x: 'foo%2F..%2Fbar' }
        '/foo/bar'            | { x: 'foo%252F..%252Fbar' }
        '/search'             | { x: 'foo/../bar' }
        '/search'             | { x: 'foo%2F..%2Fbar' }
        '/search'             | { x: 'foo%252F..%252Fbar' }
        '%2Fsearch'           | { x: 'foo/../bar' }
        '%2Fsearch'           | { x: 'foo%2F..%2Fbar' }
        '%2Fsearch'           | { x: 'foo%252F..%252Fbar' }
      end

      with_them do
        %w[get post put post delete patch].each do |http_method|
          context "when using #{http_method}" do
            let(:method) { http_method }

            it 'does not check for path traversals' do
              expect(::Gitlab::PathTraversal).not_to receive(:path_traversal?)

              subject
            end
          end
        end
      end
    end
  end
end
