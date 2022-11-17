# frozen_string_literal: true

RSpec.shared_examples 'switches to user preferred language' do |msg_id_example|
  context 'with preferred_language in cookies' do
    render_views
    let(:user_preferred_language) { 'zh_CN' }

    subject { get :new }

    before do
      cookies['preferred_language'] = user_preferred_language
    end

    it 'renders new template with cookies preferred language' do
      expect(subject).to render_template(:new)
      expect(response).to have_gitlab_http_status(:ok)

      expected_text = Gitlab::I18n.with_locale(user_preferred_language) { _(msg_id_example) }
      expect(response.body).to include(expected_text)
    end
  end
end
