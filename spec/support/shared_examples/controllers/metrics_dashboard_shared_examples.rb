# frozen_string_literal: true

RSpec.shared_examples_for 'GET #metrics_dashboard correctly formatted response' do
  it 'returns a json object with the correct keys' do
    get :metrics_dashboard, params: metrics_dashboard_req_params, format: :json

    # Exclude `all_dashboards` to handle separately, at spec/controllers/projects/environments_controller_spec.rb:565
    # because `all_dashboards` key is not part of expected shared behavior
    found_keys = json_response.keys - ['all_dashboards']

    expect(response).to have_gitlab_http_status(status_code)
    expect(found_keys).to contain_exactly(*expected_keys)
  end
end
