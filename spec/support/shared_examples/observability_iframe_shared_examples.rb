# frozen_string_literal: true

# Shared examples for any request spec that exercises a controller action
# rendering the shared/observability/_iframe partial.
#
# The including spec must have already made a request (e.g. via `get`) so that
# `response` is available when the examples run.
RSpec.shared_examples 'renders observability iframe' do
  it 'renders the observability iframe container markup' do
    expect(response).to have_gitlab_http_status(:ok)
    expect(response.body).to include('js-observability')
    expect(response.body).to include('observability-container')
    expect(response.body).to match(/data-polling-endpoint="[^"]*format=json[^"]*"/)
    expect(response.body).to include('data-query-params="{}"')
  end
end
