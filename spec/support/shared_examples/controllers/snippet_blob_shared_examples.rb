# frozen_string_literal: true

RSpec.shared_examples 'raw snippet blob' do
  context 'with valid params' do
    before do
      subject
    end

    it 'delivers file with correct Workhorse headers' do
      expect(response.header['Content-Type']).to eq('text/plain; charset=utf-8')
      expect(response.header[Gitlab::Workhorse::DETECT_HEADER]).to eq 'true'
      expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with('git-blob:')
    end

    it 'responds with status 200' do
      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  context 'Content Disposition' do
    context 'when the disposition is inline' do
      let(:inline) { true }

      it 'returns inline in the content disposition header' do
        subject

        expect(response.header['Content-Disposition']).to eq('inline')
      end
    end

    context 'when the disposition is attachment' do
      let(:inline) { false }

      it 'returns attachment plus the filename in the content disposition header' do
        subject

        expect(response.header['Content-Disposition']).to match "attachment; filename=\"#{filepath}\""
      end
    end
  end

  context 'with invalid file path' do
    let(:filepath) { 'doesnotexist' }

    it_behaves_like 'returning response status', :not_found
  end

  context 'with invalid ref' do
    let(:ref) { 'doesnotexist' }

    it_behaves_like 'returning response status', :not_found
  end

  it_behaves_like 'content disposition headers'
end

RSpec.shared_examples 'raw snippet without repository' do |unauthorized_status|
  context 'when authorized' do
    it 'returns a 422' do
      subject

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end
  end

  context 'when unauthorized' do
    let(:visibility) { :private }

    it_behaves_like 'returning response status', unauthorized_status
  end
end
