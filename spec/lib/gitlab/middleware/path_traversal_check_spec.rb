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
                .with({
                  class_name: described_class.name,
                  duration_ms: instance_of(Float),
                  status: fake_response_status
                }).and_call_original

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

    shared_examples 'excluded path' do
      it 'measures and logs the execution time' do
        expect(::Gitlab::PathTraversal)
          .not_to receive(:check_path_traversal!)
        expect(::Gitlab::AppLogger)
          .to receive(:warn)
                .with({
                  class_name: described_class.name,
                  duration_ms: instance_of(Float),
                  status: fake_response_status
                }).and_call_original

        expect(subject).to eq(fake_response)
      end

      context 'with log_execution_time_path_traversal_middleware disabled' do
        before do
          stub_feature_flags(log_execution_time_path_traversal_middleware: false)
        end

        it 'does nothing' do
          expect(::Gitlab::PathTraversal)
            .not_to receive(:check_path_traversal!)
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
                  method: method.upcase,
                  status: fake_response_status
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
                    method: method.upcase,
                    status: fake_response_status
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
        '/foo/bar'            | {}                           | 'no issue'
        '/foo/../bar'         | {}                           | 'path traversal'
        '/foo%2Fbar'          | {}                           | 'no issue'
        '/foo%2F..%2Fbar'     | {}                           | 'path traversal'
        '/foo%252F..%252Fbar' | {}                           | 'no issue'

        '/foo/bar'            | { x: 'foo' }                 | 'no issue'
        '/foo/bar'            | { x: 'foo/../bar' }          | 'path traversal'
        '/foo/bar'            | { x: 'foo%2Fbar' }           | 'no issue'
        '/foo/bar'            | { x: 'foo%2F..%2Fbar' }      | 'no issue'
        '/foo/bar'            | { x: 'foo%252F..%252Fbar' }  | 'no issue'
        '/foo%2F..%2Fbar'     | { x: 'foo%252F..%252Fbar' }  | 'path traversal'
      end

      with_them do
        it_behaves_like params[:shared_example_name]
      end

      context 'for global search excluded paths' do
        excluded_paths = %w[
          /search
          /search/count
          /api/v4/search
          /api/v4/search.json
          /api/v4/projects/4/search
          /api/v4/projects/4/search.json
          /api/v4/projects/4/-/search
          /api/v4/projects/4/-/search.json
          /api/v4/projects/my%2Fproject/search
          /api/v4/projects/my%2Fproject/search.json
          /api/v4/projects/my%2Fproject/-/search
          /api/v4/projects/my%2Fproject/-/search.json
          /api/v4/groups/4/search
          /api/v4/groups/4/search.json
          /api/v4/groups/4/-/search
          /api/v4/groups/4/-/search.json
          /api/v4/groups/my%2Fgroup/search
          /api/v4/groups/my%2Fgroup/search.json
          /api/v4/groups/my%2Fgroup/-/search
          /api/v4/groups/my%2Fgroup/-/search.json
        ]
        query_params_with_no_path_traversal = [
          {},
          { x: 'foo' },
          { x: 'foo%2F..%2Fbar' },
          { x: 'foo%2F..%2Fbar' },
          { x: 'foo%252F..%252Fbar' }
        ]
        query_params_with_path_traversal = [
          { x: 'foo/../bar' }
        ]

        excluded_paths.each do |excluded_path|
          [query_params_with_no_path_traversal + query_params_with_path_traversal].flatten.each do |qp|
            context "for excluded path #{excluded_path} with query params #{qp}" do
              let(:query_params) { qp }
              let(:path) { excluded_path }

              it_behaves_like 'excluded path'
            end
          end

          non_excluded_path = excluded_path.gsub('search', 'searchtest')

          query_params_with_no_path_traversal.each do |qp|
            context "for non excluded path #{non_excluded_path} with query params #{qp}" do
              let(:query_params) { qp }
              let(:path) { non_excluded_path }

              it_behaves_like 'no issue'
            end
          end

          query_params_with_path_traversal.each do |qp|
            context "for non excluded path #{non_excluded_path} with query params #{qp}" do
              let(:query_params) { qp }
              let(:path) { non_excluded_path }

              it_behaves_like 'path traversal'
            end
          end
        end
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

        context 'for global search excluded paths' do
          excluded_paths = %w[
            /search
            /search/count
            /api/v4/search
            /api/v4/search.json
            /api/v4/projects/4/search
            /api/v4/projects/4/search.json
            /api/v4/projects/4/-/search
            /api/v4/projects/4/-/search.json
            /api/v4/projects/my%2Fproject/search
            /api/v4/projects/my%2Fproject/search.json
            /api/v4/projects/my%2Fproject/-/search
            /api/v4/projects/my%2Fproject/-/search.json
            /api/v4/groups/4/search
            /api/v4/groups/4/search.json
            /api/v4/groups/4/-/search
            /api/v4/groups/4/-/search.json
            /api/v4/groups/my%2Fgroup/search
            /api/v4/groups/my%2Fgroup/search.json
            /api/v4/groups/my%2Fgroup/-/search
            /api/v4/groups/my%2Fgroup/-/search.json
          ]
          all_query_params = [
            {},
            { x: 'foo' },
            { x: 'foo%2F..%2Fbar' },
            { x: 'foo%2F..%2Fbar' },
            { x: 'foo%252F..%252Fbar' },
            { x: 'foo/../bar' }
          ]

          excluded_paths.each do |excluded_path|
            all_query_params.each do |qp|
              context "for excluded path #{excluded_path} with query params #{qp}" do
                let(:query_params) { qp }
                let(:path) { excluded_path }

                it_behaves_like 'excluded path'
              end

              non_excluded_path = excluded_path.gsub('search', 'searchtest')

              context "for non excluded path #{non_excluded_path} with query params #{qp}" do
                let(:query_params) { qp }
                let(:path) { excluded_path.gsub('search', 'searchtest') }

                it_behaves_like 'no issue'
              end
            end
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
