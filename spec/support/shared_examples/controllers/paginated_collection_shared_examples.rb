# frozen_string_literal: true

RSpec.shared_examples 'paginated collection' do
  let(:collection) { nil }
  let(:last_page) { collection.page.total_pages }
  let(:action) { :index }
  let(:params) { {} }

  it 'renders a page number that is not ouf of range' do
    get action, params: params.merge(page: last_page)

    expect(response).to have_gitlab_http_status(:ok)
  end

  it 'redirects to last_page if page number is larger than number of pages' do
    get action, params: params.merge(page: last_page + 1)

    expect(response).to redirect_to(params.merge(page: last_page))
  end

  it 'does not redirect to external sites when provided a host field' do
    external_host = 'www.example.com'

    get action, params: params.merge(page: last_page + 1, host: external_host)

    expect(response).to redirect_to(params.merge(page: last_page))
  end
end
