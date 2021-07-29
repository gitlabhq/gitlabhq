# frozen_string_literal: true

RSpec.shared_examples 'write access for a read-only GitLab instance' do
  include Rack::Test::Methods
  using RSpec::Parameterized::TableSyntax

  include_context 'with a mocked GitLab instance'

  context 'normal requests to a read-only GitLab instance' do
    let(:fake_app) { lambda { |env| [200, { 'Content-Type' => 'text/plain' }, ['OK']] } }

    it 'expects PATCH requests to be disallowed' do
      response = request.patch('/test_request')

      expect(response).to be_redirect
      expect(subject).to disallow_request
    end

    it 'expects PUT requests to be disallowed' do
      response = request.put('/test_request')

      expect(response).to be_redirect
      expect(subject).to disallow_request
    end

    it 'expects POST requests to be disallowed' do
      response = request.post('/test_request')

      expect(response).to be_redirect
      expect(subject).to disallow_request
    end

    it 'expects a internal POST request to be allowed after a disallowed request' do
      response = request.post('/test_request')

      expect(response).to be_redirect

      response = request.post("/api/#{API::API.version}/internal")

      expect(response).not_to be_redirect
    end

    it 'expects DELETE requests to be disallowed' do
      response = request.delete('/test_request')

      expect(response).to be_redirect
      expect(subject).to disallow_request
    end

    it 'expects POST of new file that looks like an LFS batch url to be disallowed' do
      expect(Rails.application.routes).to receive(:recognize_path).and_call_original
      response = request.post('/root/gitlab-ce/new/master/app/info/lfs/objects/batch')

      expect(response).to be_redirect
      expect(subject).to disallow_request
    end

    it 'returns last_vistited_url for disallowed request' do
      response = request.post('/test_request')

      expect(response.location).to eq 'http://localhost/'
    end

    context 'allowlisted requests' do
      it 'expects a POST internal request to be allowed' do
        expect(Rails.application.routes).not_to receive(:recognize_path)
        response = request.post("/api/#{API::API.version}/internal")

        expect(response).not_to be_redirect
        expect(subject).not_to disallow_request
      end

      it 'expects a POST internal request with trailing slash to be allowed' do
        expect(Rails.application.routes).not_to receive(:recognize_path)
        response = request.post("/api/#{API::API.version}/internal/")

        expect(response).not_to be_redirect
        expect(subject).not_to disallow_request
      end

      it 'expects a graphql request to be allowed' do
        response = request.post("/api/graphql")

        expect(response).not_to be_redirect
        expect(subject).not_to disallow_request
      end

      it 'expects a graphql request with trailing slash to be allowed' do
        response = request.post("/api/graphql/")

        expect(response).not_to be_redirect
        expect(subject).not_to disallow_request
      end

      context 'relative URL is configured' do
        before do
          stub_config_setting(relative_url_root: '/gitlab')
        end

        it 'expects a graphql request to be allowed' do
          response = request.post("/gitlab/api/graphql")

          expect(response).not_to be_redirect
          expect(subject).not_to disallow_request
        end

        it 'expects a graphql request with trailing slash to be allowed' do
          response = request.post("/gitlab/api/graphql/")

          expect(response).not_to be_redirect
          expect(subject).not_to disallow_request
        end
      end

      context 'sidekiq admin requests' do
        where(:mounted_at) do
          [
            '',
            '/',
            '/gitlab',
            '/gitlab/',
            '/gitlab/gitlab',
            '/gitlab/gitlab/'
          ]
        end

        with_them do
          before do
            stub_config_setting(relative_url_root: mounted_at)
          end

          it 'allows requests' do
            path = File.join(mounted_at, 'admin/sidekiq')
            response = request.post(path)

            expect(response).not_to be_redirect
            expect(subject).not_to disallow_request

            response = request.get(path)

            expect(response).not_to be_redirect
            expect(subject).not_to disallow_request
          end

          it 'allows requests with trailing slash' do
            path = File.join(mounted_at, 'admin/sidekiq')
            response = request.post("#{path}/")

            expect(response).not_to be_redirect
            expect(subject).not_to disallow_request

            response = request.get("#{path}/")

            expect(response).not_to be_redirect
            expect(subject).not_to disallow_request
          end
        end
      end

      where(:description, :path) do
        'LFS request to batch'        | '/root/rouge.git/info/lfs/objects/batch'
        'request to git-upload-pack'  | '/root/rouge.git/git-upload-pack'
        'user sign out'               | '/users/sign_out'
        'admin session'               | '/admin/session'
        'admin session destroy'       | '/admin/session/destroy'
      end

      with_them do
        it "expects a POST #{description} URL to be allowed" do
          expect(Rails.application.routes).to receive(:recognize_path).and_call_original
          response = request.post(path)

          expect(response).not_to be_redirect
          expect(subject).not_to disallow_request
        end

        it "expects a POST #{description} URL with trailing slash to be allowed" do
          expect(Rails.application.routes).to receive(:recognize_path).and_call_original
          response = request.post("#{path}/")

          expect(response).not_to be_redirect
          expect(subject).not_to disallow_request
        end
      end

      where(:description, :path) do
        'LFS request to locks verify' | '/root/rouge.git/info/lfs/locks/verify'
        'LFS request to locks create' | '/root/rouge.git/info/lfs/locks'
        'LFS request to locks unlock' | '/root/rouge.git/info/lfs/locks/1/unlock'
      end

      with_them do
        it "expects a POST #{description} URL not to be allowed" do
          response = request.post(path)

          expect(response).to be_redirect
          expect(subject).to disallow_request
        end

        it "expects a POST #{description} URL with trailing slash not to be allowed" do
          response = request.post("#{path}/")

          expect(response).to be_redirect
          expect(subject).to disallow_request
        end
      end
    end
  end

  context 'JSON requests to a read-only GitLab instance' do
    let(:fake_app) { lambda { |env| [200, { 'Content-Type' => 'application/json' }, ['OK']] } }
    let(:content_json) { { 'CONTENT_TYPE' => 'application/json' } }

    before do
      allow(Gitlab::Database.main).to receive(:read_only?) { true }
    end

    it 'expects PATCH requests to be disallowed' do
      response = request.patch('/test_request', content_json)

      expect(response).to disallow_request_in_json
    end

    it 'expects PUT requests to be disallowed' do
      response = request.put('/test_request', content_json)

      expect(response).to disallow_request_in_json
    end

    it 'expects POST requests to be disallowed' do
      response = request.post('/test_request', content_json)

      expect(response).to disallow_request_in_json
    end

    it 'expects DELETE requests to be disallowed' do
      response = request.delete('/test_request', content_json)

      expect(response).to disallow_request_in_json
    end
  end
end
