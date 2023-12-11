# frozen_string_literal: true

RSpec.shared_examples 'web-hook API endpoints test hook' do |prefix|
  describe "POST #{prefix}/:hook_id", :aggregate_failures do
    it 'tests the hook' do
      expect(WebHookService)
        .to receive(:new).with(hook, anything, String, force: false)
        .and_return(instance_double(WebHookService, execute: nil))

      post api(hook_uri, user, admin_mode: user.admin?)

      expect(response).to have_gitlab_http_status(:created)
    end
  end
end

RSpec.shared_examples 'web-hook API endpoints with branch-filter' do |prefix|
  describe "POST #{prefix}/hooks" do
    it "returns a 422 error if branch filter is not valid" do
      post api(collection_uri, user, admin_mode: user.admin?),
        params: { url: "http://example.com", push_events_branch_filter: '~badbranchname/' }

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end
  end
end

RSpec.shared_examples 'web-hook API endpoints' do |prefix|
  def hooks_count
    scope.count
  end

  def hook_param_overrides
    if defined?(super)
      super
    else
      { push_events_branch_filter: 'some-feature-branch' }
    end
  end

  let(:hook_params) do
    event_names.to_h { [_1, true] }.merge(hook_param_overrides).merge(
      url: "http://example.com",
      url_variables: [
        { key: 'token', value: 'very-secret' },
        { key: 'abc', value: 'other value' }
      ]
    )
  end

  let(:update_params) do
    {
      push_events: false,
      job_events: true,
      push_events_branch_filter: 'updated-branch-filter'
    }
  end

  let(:default_values) { {} }

  describe "GET #{prefix}/hooks", :aggregate_failures do
    context "authorized user" do
      it "returns all hooks" do
        get api(collection_uri, user, admin_mode: user.admin?)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_collection_schema
      end
    end

    context "when user is forbidden" do
      it "prevents access to hooks" do
        get api(collection_uri, unauthorized_user, admin_mode: true)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context "when user is unauthorized" do
      it "prevents access to hooks" do
        get api(collection_uri, nil)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'the hook has URL variables', if: prefix != '/projects/:id' do
      before do
        hook.update!(url_variables: { 'token' => 'supers3cret' })
      end

      it 'returns the names of the url variables' do
        get api(collection_uri, user, admin_mode: user.admin?)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to contain_exactly(
          a_hash_including(
            'url_variables' => [{ 'key' => 'token' }]
          )
        )
      end
    end
  end

  describe "GET #{prefix}/hooks/:hook_id", :aggregate_failures do
    context "authorized user" do
      it "returns a project hook" do
        get api(hook_uri, user, admin_mode: user.admin?)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_hook_schema

        expect(json_response['url']).to eq(hook.url)
      end

      it "returns a 404 error if hook id is not available" do
        get api(hook_uri(non_existing_record_id), user, admin_mode: user.admin?)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'the hook is disabled' do
        before do
          hook.update!(recent_failures: hook.class::EXCEEDED_FAILURE_THRESHOLD)
        end

        it "has the correct alert status", :aggregate_failures do
          get api(hook_uri, user, admin_mode: user.admin?)

          expect(response).to have_gitlab_http_status(:ok)

          expect(json_response).to include('alert_status' => 'disabled') unless hook.executable?
        end
      end

      context 'the hook is backed-off' do
        before do
          WebHooks::AutoDisabling::FAILURE_THRESHOLD.times { hook.backoff! }
          hook.backoff!
        end

        it "has the correct alert status", :aggregate_failures do
          get api(hook_uri, user, admin_mode: user.admin?)

          expect(response).to have_gitlab_http_status(:ok)

          unless hook.executable?
            expect(json_response).to include(
              'alert_status' => 'temporarily_disabled',
              'disabled_until' => hook.disabled_until.iso8601(3)
            )
          end
        end
      end
    end

    context "when user is forbidden" do
      it "does not access an existing hook" do
        get api(hook_uri, unauthorized_user, admin_mode: true)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context "when user is unauthorized" do
      it "does not access an existing hook" do
        get api(hook_uri, nil)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe "POST #{prefix}/hooks", :aggregate_failures do
    let(:hook_creation_params) { hook_params }

    it "adds hook", :aggregate_failures do
      expect do
        post api(collection_uri, user, admin_mode: user.admin?), params: hook_creation_params
      end.to change { hooks_count }.by(1)

      expect(response).to have_gitlab_http_status(:created)
      expect(response).to match_hook_schema

      expect(json_response['url']).to eq(hook_creation_params[:url])
      hook_param_overrides.each do |k, v|
        expect(json_response[k.to_s]).to eq(v)
      end
      event_names.each do |name|
        expect(json_response[name.to_s]).to eq(true), name
      end
      expect(json_response['url_variables']).to match_array [
        { 'key' => 'token' },
        { 'key' => 'abc' }
      ]
      expect(json_response).not_to include('token')
    end

    it "adds the token without including it in the response" do
      token = "secret token"

      expect do
        post api(collection_uri, user, admin_mode: user.admin?), params: { url: "http://example.com", token: token }
      end.to change { hooks_count }.by(1)

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response["url"]).to eq("http://example.com")
      expect(json_response).not_to include("token")

      hook = scope.find(json_response["id"])

      expect(hook.url).to eq("http://example.com")
      expect(hook.token).to eq(token)
    end

    it "returns a 400 error if url not given" do
      post api(collection_uri, user, admin_mode: user.admin?), params: { event_names.first => true }

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it "returns a 400 error if no parameters are provided" do
      post api(collection_uri, user, admin_mode: user.admin?)

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'sets default values for events', :aggregate_failures do
      post api(collection_uri, user, admin_mode: user.admin?), params: { url: 'http://mep.mep' }

      expect(response).to have_gitlab_http_status(:created)
      expect(response).to match_hook_schema
      expect(json_response['enable_ssl_verification']).to be true
      event_names.each do |name|
        expect(json_response[name.to_s]).to eq(default_values.fetch(name, false)), name
      end
    end

    it "returns a 422 error if token not valid" do
      post api(collection_uri, user, admin_mode: user.admin?),
        params: { url: "http://example.com", token: "foo\nbar" }

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end

    it "returns a 422 error if url not valid" do
      post api(collection_uri, user, admin_mode: user.admin?), params: { url: "ftp://example.com" }

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end
  end

  describe "PUT #{prefix}/hooks/:hook_id", :aggregate_failures do
    it "updates an existing hook" do
      put api(hook_uri, user, admin_mode: user.admin?), params: update_params

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_hook_schema

      update_params.each do |k, v|
        expect(json_response[k.to_s]).to eq(v)
      end
    end

    it 'updates the URL variables' do
      hook.update!(url_variables: { 'abc' => 'some value' })

      put api(hook_uri, user, admin_mode: user.admin?),
        params: { url_variables: [{ key: 'def', value: 'other value' }] }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['url_variables']).to match_array [
        { 'key' => 'abc' },
        { 'key' => 'def' }
      ]
    end

    it "adds the token without including it in the response" do
      token = "secret token"

      put api(hook_uri, user, admin_mode: user.admin?), params: { url: "http://example.org", token: token }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response["url"]).to eq("http://example.org")
      expect(json_response).not_to include("token")

      expect(hook.reload.url).to eq("http://example.org")
      expect(hook.reload.token).to eq(token)
    end

    it "returns 404 error if hook id not found" do
      put api(hook_uri(non_existing_record_id), user, admin_mode: user.admin?), params: { url: 'http://example.org' }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it "returns 400 error if no parameters are provided" do
      put api(hook_uri, user, admin_mode: user.admin?)

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it "returns a 422 error if url is not valid" do
      put api(hook_uri, user, admin_mode: user.admin?), params: { url: 'ftp://example.com' }

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end

    it "returns a 422 error if token is not valid" do
      put api(hook_uri, user, admin_mode: user.admin?), params: { token: %w[foo bar].join("\n") }

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /projects/:id/hooks/:hook_id", :aggregate_failures do
    it "deletes hook from project" do
      expect do
        delete api(hook_uri, user, admin_mode: user.admin?)

        expect(response).to have_gitlab_http_status(:no_content)
      end.to change { hooks_count }.by(-1)
    end

    it "returns a 404 error when deleting non existent hook" do
      delete api(hook_uri(non_existing_record_id), user, admin_mode: user.admin?)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it "returns a 404 error if hook id not given" do
      delete api(collection_uri, user, admin_mode: user.admin?)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it "returns forbidden if a user attempts to delete hooks they do not own" do
      delete api(hook_uri, unauthorized_user, admin_mode: true)

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(WebHook.exists?(hook.id)).to be_truthy
    end

    it_behaves_like '412 response' do
      let(:request) { api(hook_uri, user, admin_mode: user.admin?) }
    end
  end

  describe "PUT #{prefix}/hooks/:hook_id/url_variables/:key", :aggregate_failures do
    it 'sets the variable' do
      expect do
        put api("#{hook_uri}/url_variables/abc", user, admin_mode: user.admin?),
          params: { value: 'some secret value' }
      end.to change { hook.reload.url_variables }.to(eq('abc' => 'some secret value'))

      expect(response).to have_gitlab_http_status(:no_content)
    end

    it 'overwrites existing values' do
      hook.update!(url_variables: { 'abc' => 'xyz', 'def' => 'other value' })

      put api("#{hook_uri}/url_variables/abc", user, admin_mode: user.admin?),
        params: { value: 'some secret value' }

      expect(response).to have_gitlab_http_status(:no_content)
      expect(hook.reload.url_variables).to eq('abc' => 'some secret value', 'def' => 'other value')
    end

    it "returns a 404 error when editing non existent hook" do
      put api("#{hook_uri(non_existing_record_id)}/url_variables/abc", user, admin_mode: user.admin?),
        params: { value: 'xyz' }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it "returns a 422 error when the key is illegal" do
      put api("#{hook_uri}/url_variables/abc%20def", user, admin_mode: user.admin?),
        params: { value: 'xyz' }

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end

    it "returns a 422 error when the value is illegal" do
      put api("#{hook_uri}/url_variables/abc", user, admin_mode: user.admin?),
        params: { value: '' }

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE #{prefix}/hooks/:hook_id/url_variables/:key", :aggregate_failures do
    before do
      hook.update!(url_variables: { 'abc' => 'prior value', 'def' => 'other value' })
    end

    it 'unsets the variable' do
      expect do
        delete api("#{hook_uri}/url_variables/abc", user, admin_mode: user.admin?)
      end.to change { hook.reload.url_variables }.to(eq({ 'def' => 'other value' }))

      expect(response).to have_gitlab_http_status(:no_content)
    end

    it 'returns 404 for keys that do not exist' do
      hook.update!(url_variables: { 'def' => 'other value' })

      delete api("#{hook_uri}/url_variables/abc", user, admin_mode: user.admin?)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it "returns a 404 error when deleting a variable from a non existent hook" do
      delete api(hook_uri(non_existing_record_id) + "/url_variables/abc", user, admin_mode: user.admin?)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
