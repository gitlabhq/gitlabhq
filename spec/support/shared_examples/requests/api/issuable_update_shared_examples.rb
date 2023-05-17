# frozen_string_literal: true

RSpec.shared_examples 'issuable update endpoint' do
  let(:area) { entity.class.name.underscore.pluralize }

  describe 'PUT /projects/:id/issues/:issue_iid' do
    let(:url) { "/projects/#{project.id}/#{area}/#{entity.iid}" }

    it 'clears labels when labels param is nil' do
      put api(url, user), params: { labels: 'label1' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['labels']).to contain_exactly('label1')

      put api(url, user), params: { labels: nil }

      expect(response).to have_gitlab_http_status(:ok)
      json_response = Gitlab::Json.parse(response.body)
      expect(json_response['labels']).to be_empty
    end

    it 'updates the issuable with labels param as array' do
      allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(110)

      params = { labels: ['label1', 'label2', 'foo, bar', '&,?'] }

      put api(url, user), params: params

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['labels']).to include 'label1'
      expect(json_response['labels']).to include 'label2'
      expect(json_response['labels']).to include 'foo'
      expect(json_response['labels']).to include 'bar'
      expect(json_response['labels']).to include '&'
      expect(json_response['labels']).to include '?'
    end

    it 'clears milestone when milestone_id=0' do
      entity.update!(milestone: milestone)

      put api(url, user), params: { milestone_id: 0 }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['milestone']).to be_nil
    end
  end
end
