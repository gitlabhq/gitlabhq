# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Middleware::PathTraversalCheck, feature_category: :shared do
  using RSpec::Parameterized::TableSyntax

  let(:fake_response_status) { 200 }
  let(:fake_response) { [fake_response_status, { 'Content-Type' => 'text/plain' }, ['OK']] }
  let(:fake_app) { ->(_) { fake_response } }

  describe '#call' do
    let(:fullpath) { ::ActionDispatch::Request.new(env).filtered_path }
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
      path_with_query_params = [path, querify(query_params).presence].compact.join('?')
      Rack::MockRequest.env_for(path_with_query_params, method: method)
    end

    subject { described_class.new(fake_app).call(env) }

    shared_examples 'no issue' do
      it 'does not log or reject the request' do
        expect(::Gitlab::PathTraversal)
          .to receive(:path_traversal?)
                .with(decoded_fullpath, match_new_line: false)
                .and_call_original
        expect(::Gitlab::AppLogger).not_to receive(:warn)
        expect(::Gitlab::Instrumentation::Middleware::PathTraversalCheck)
          .to receive(:duration=).with(an_instance_of(Float))
        expect(::Gitlab::Metrics::Middleware::PathTraversalCheck)
          .to receive(:increment).with(
            labels: { request_rejected: false },
            duration: an_instance_of(Float)
          )

        expect(subject).to eq(fake_response)
      end
    end

    shared_examples 'path traversal' do
      it 'logs and rejects the request' do
        expect(::Gitlab::PathTraversal)
          .to receive(:path_traversal?)
                .with(decoded_fullpath, match_new_line: false)
                .and_call_original
        expect(::Gitlab::AppLogger)
          .to receive(:warn)
                .with(hash_including(
                  class_name: described_class.name,
                  message: described_class::PATH_TRAVERSAL_MESSAGE,
                  fullpath: fullpath,
                  method: method.upcase,
                  request_rejected: true
                )).and_call_original
        expect(::Gitlab::Instrumentation::Middleware::PathTraversalCheck)
          .to receive(:duration=).with(an_instance_of(Float))
        expect(::Gitlab::Metrics::Middleware::PathTraversalCheck)
          .to receive(:increment).with(
            labels: { request_rejected: true },
            duration: an_instance_of(Float)
          )

        expect(subject).to eq(described_class::REJECT_RESPONSE)
      end
    end

    %w[get post put patch delete].each do |http_method|
      context "when using #{http_method}" do
        let(:method) { http_method }

        where(:path, :query_params, :shared_example_name) do
          '/foo/bar'            | {}                                   | 'no issue'
          '/foo/../bar'         | {}                                   | 'path traversal'
          '/foo%2Fbar'          | {}                                   | 'no issue'
          '/foo%2F..%2Fbar'     | {}                                   | 'path traversal'
          '/foo%252F..%252Fbar' | {}                                   | 'no issue'

          '/foo/bar'            | { x: 'foo' }                         | 'no issue'
          '/foo/bar'            | { x: 'foo/../bar' }                  | 'path traversal'
          '/foo/bar'            | { x: 'foo%2Fbar' }                   | 'no issue'
          '/foo/bar'            | { x: 'foo%2F..%2Fbar' }              | 'path traversal'
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
            let(:query_params) { { param_name => 'an/../attempt', :x => 'test' } }
            let(:decoded_fullpath) { '/foo/bar?x=test' }

            it_behaves_like 'no issue'
          end

          context "with the excluded query parameter #{param_name} nested one level" do
            let(:path) { '/foo/bar' }
            let(:query_params) { { "level_1[#{param_name}]" => 'an/../attempt', :x => 'test' } }
            let(:decoded_fullpath) { '/foo/bar?x=test' }

            it_behaves_like 'no issue'
          end

          context "with the excluded query parameter #{param_name} nested two levels" do
            let(:path) { '/foo/bar' }
            let(:query_params) { { "level_1[level_2][#{param_name}]" => 'an/../attempt', :x => 'test' } }
            let(:decoded_fullpath) { '/foo/bar?x=test' }

            it_behaves_like 'no issue'
          end

          context "with the excluded query parameter #{param_name} nested above the max level" do
            let(:path) { '/foo/bar' }

            let(:query_params) do
              {
                "level_1[level_2][level_3][level_4][level_5][level_6][#{param_name}]" => 'an/../attempt',
                :x => 'test'
              }
            end

            it_behaves_like 'path traversal'
          end
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
        %w[get post put patch delete].each do |http_method|
          context "when using #{http_method}" do
            let(:method) { http_method }

            it 'does not check for path traversals' do
              expect(::Gitlab::PathTraversal).not_to receive(:path_traversal?)
              expect(::Gitlab::Instrumentation::Middleware::PathTraversalCheck).not_to receive(:duration)
              expect(::Gitlab::Metrics::Middleware::PathTraversalCheck).not_to receive(:increment)

              subject
            end
          end
        end
      end
    end

    context 'with check_path_traversal_middleware_reject_requests disabled' do
      before do
        stub_feature_flags(check_path_traversal_middleware_reject_requests: false)
      end

      shared_examples 'path traversal' do
        it 'logs and accepts the request' do
          expect(::Gitlab::PathTraversal)
            .to receive(:path_traversal?)
                  .with(decoded_fullpath, match_new_line: false)
                  .and_call_original
          expect(::Gitlab::AppLogger)
            .to receive(:warn)
                  .with(hash_including(
                    class_name: described_class.name,
                    message: described_class::PATH_TRAVERSAL_MESSAGE,
                    fullpath: fullpath,
                    method: method.upcase,
                    status: fake_response_status
                  )).and_call_original
          expect(::Gitlab::Instrumentation::Middleware::PathTraversalCheck)
            .to receive(:duration=).with(an_instance_of(Float))
          expect(::Gitlab::Metrics::Middleware::PathTraversalCheck)
            .to receive(:increment).with(
              labels: { request_rejected: false },
              duration: an_instance_of(Float)
            )

          expect(subject).to eq(fake_response)
        end
      end

      where(:path, :query_params, :shared_example_name) do
        '/foo/bar'            | {}                          | 'no issue'
        '/foo/../bar'         | {}                          | 'path traversal'
        '/foo%2Fbar'          | {}                          | 'no issue'
        '/foo%2F..%2Fbar'     | {}                          | 'path traversal'
        '/foo%252F..%252Fbar' | {}                          | 'no issue'
        '/foo/bar'            | { x: 'foo' }                | 'no issue'
        '/foo/bar'            | { x: 'foo/../bar' }         | 'path traversal'
        '/foo/bar'            | { x: 'foo%2Fbar' }          | 'no issue'
        '/foo/bar'            | { x: 'foo%2F..%2Fbar' }     | 'path traversal'
        '/foo/bar'            | { x: 'foo%252F..%252Fbar' } | 'no issue'
        '/search'             | { x: 'foo/../bar' }         | 'path traversal'
        '/search'             | { x: 'foo%2F..%2Fbar' }     | 'path traversal'
        '/search'             | { x: 'foo%252F..%252Fbar' } | 'no issue'
        '%2Fsearch'           | { x: 'foo/../bar' }         | 'path traversal'
        '%2Fsearch'           | { x: 'foo%2F..%2Fbar' }     | 'path traversal'
        '%2Fsearch'           | { x: 'foo%252F..%252Fbar' } | 'no issue'
      end

      with_them do
        %w[get post put patch delete].each do |http_method|
          context "when using #{http_method}" do
            let(:method) { http_method }

            it_behaves_like params[:shared_example_name]
          end
        end
      end
    end

    # Can't use params.to_query as #to_query will encode values
    def querify(params)
      params.map { |k, v| "#{k}=#{v}" }.join('&')
    end
  end
end
