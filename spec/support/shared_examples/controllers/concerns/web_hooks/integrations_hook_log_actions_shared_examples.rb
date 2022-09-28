# frozen_string_literal: true

RSpec.shared_examples WebHooks::HookLogActions do
  let!(:show_path) { web_hook_log.present.details_path }
  let!(:retry_path) { web_hook_log.present.retry_path }

  before do
    sign_in(user)
  end

  describe 'GET #show' do
    it 'renders a 200 if the hook exists' do
      get show_path

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template('hook_logs/show')
    end

    it 'renders a 404 if the hook does not exist' do
      web_hook.destroy!
      get show_path

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'POST #retry' do
    it 'executes the hook and redirects to the service form' do
      stub_request(:post, web_hook.interpolated_url)

      expect_next_found_instance_of(web_hook.class) do |hook|
        expect(hook).to receive(:execute).and_call_original
      end

      post retry_path

      expect(response).to redirect_to(edit_hook_path)
    end

    it 'renders a 404 if the hook does not exist' do
      web_hook.destroy!
      post retry_path

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
