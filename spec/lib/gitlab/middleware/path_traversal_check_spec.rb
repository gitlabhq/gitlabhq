# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Middleware::PathTraversalCheck, feature_category: :shared do
  using RSpec::Parameterized::TableSyntax

  let(:fake_response) { [200, { 'Content-Type' => 'text/plain' }, ['OK']] }
  let(:fake_app) { ->(_) { fake_response } }
  let(:middleware) { described_class.new(fake_app) }

  describe '#call' do
    let(:fullpath) { ::Rack::Request.new(env).fullpath }
    let(:decoded_fullpath) { CGI.unescape(fullpath) }

    let(:env) do
      Rack::MockRequest.env_for(
        path,
        method: method,
        params: query_params
      )
    end

    subject { middleware.call(env) }

    shared_examples 'no issue' do
      it 'measures and logs the execution time' do
        expect(::Gitlab::PathTraversal)
          .to receive(:check_path_traversal!)
                .with(decoded_fullpath, skip_decoding: true)
                .and_call_original
        expect(::Gitlab::AppLogger)
          .to receive(:warn)
                .with({ class_name: described_class.name, duration_ms: instance_of(Float) })
                .and_call_original

        expect(subject).to eq(fake_response)
      end

      context 'with log_execution_time_path_traversal_middleware disabled' do
        before do
          stub_feature_flags(log_execution_time_path_traversal_middleware: false)
        end

        it 'does nothing' do
          expect(::Gitlab::PathTraversal)
            .to receive(:check_path_traversal!)
                  .with(decoded_fullpath, skip_decoding: true)
                  .and_call_original
          expect(::Gitlab::AppLogger)
            .not_to receive(:warn)

          expect(subject).to eq(fake_response)
        end
      end
    end

    shared_examples 'path traversal' do
      it 'logs the problem and measures the execution time' do
        expect(::Gitlab::PathTraversal)
          .to receive(:check_path_traversal!)
                .with(decoded_fullpath, skip_decoding: true)
                .and_call_original
        expect(::Gitlab::AppLogger)
          .to receive(:warn)
                .with({ message: described_class::PATH_TRAVERSAL_MESSAGE, path: instance_of(String) })
        expect(::Gitlab::AppLogger)
          .to receive(:warn)
                .with({
                  class_name: described_class.name,
                  duration_ms: instance_of(Float),
                  message: described_class::PATH_TRAVERSAL_MESSAGE,
                  fullpath: fullpath,
                  method: method.upcase
                }).and_call_original

        expect(subject).to eq(fake_response)
      end

      context 'with log_execution_time_path_traversal_middleware disabled' do
        before do
          stub_feature_flags(log_execution_time_path_traversal_middleware: false)
        end

        it 'logs the problem without the execution time' do
          expect(::Gitlab::PathTraversal)
            .to receive(:check_path_traversal!)
                  .with(decoded_fullpath, skip_decoding: true)
                  .and_call_original
          expect(::Gitlab::AppLogger)
            .to receive(:warn)
                  .with({ message: described_class::PATH_TRAVERSAL_MESSAGE, path: instance_of(String) })
          expect(::Gitlab::AppLogger)
            .to receive(:warn)
                  .with({
                    class_name: described_class.name,
                    message: described_class::PATH_TRAVERSAL_MESSAGE,
                    fullpath: fullpath,
                    method: method.upcase
                  }).and_call_original

          expect(subject).to eq(fake_response)
        end
      end
    end

    # we use Rack request.full_path, this will dump the accessed path and
    # the query string. The query string is only for GETs requests.
    # Hence different expectation (when params are set) for GETs and
    # the other methods (see below)
    context 'when using get' do
      let(:method) { 'get' }

      where(:path, :query_params, :shared_example_name) do
        '/foo/bar'            | {}                          | 'no issue'
        '/foo/../bar'         | {}                          | 'path traversal'
        '/foo%2Fbar'          | {}                          | 'no issue'
        '/foo%2F..%2Fbar'     | {}                          | 'path traversal'
        '/foo%252F..%252Fbar' | {}                          | 'no issue'
        '/foo/bar'            | { x: 'foo' }                | 'no issue'
        '/foo/bar'            | { x: 'foo/../bar' }         | 'path traversal'
        '/foo/bar'            | { x: 'foo%2Fbar' }          | 'no issue'
        '/foo/bar'            | { x: 'foo%2F..%2Fbar' }     | 'no issue'
        '/foo/bar'            | { x: 'foo%252F..%252Fbar' } | 'no issue'
        '/foo%2F..%2Fbar'     | { x: 'foo%252F..%252Fbar' } | 'path traversal'
      end

      with_them do
        it_behaves_like params[:shared_example_name]
      end

      context 'with a issues search path' do
        let(:query_params) { {} }
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
      end

      with_them do
        %w[get post put post delete patch].each do |http_method|
          context "when using #{http_method}" do
            let(:method) { http_method }

            it 'does not check for path traversals' do
              expect(::Gitlab::PathTraversal).not_to receive(:check_path_traversal!)

              subject
            end
          end
        end
      end
    end
  end
end
