# frozen_string_literal: true

RSpec.shared_examples 'content disposition headers' do
  it 'sets content disposition to inline' do
    subject

    expect(response).to have_gitlab_http_status(:ok)
    expect(response.header['Content-Disposition']).to match(/inline/)
  end

  context 'when inline param is false' do
    let(:inline) { 'false' }

    it 'sets content disposition to attachment' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.header['Content-Disposition']).to match(/attachment/)
    end
  end
end
