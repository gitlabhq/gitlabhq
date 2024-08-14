# frozen_string_literal: true

module ApiHelpers
  # Public: Prepend a request path with the path to the API
  #
  # path - Path to append
  # user - User object - If provided, automatically appends private_token query
  #          string for authenticated requests
  #
  # Examples
  #
  #   >> api('/issues')
  #   => "/api/v2/issues"
  #
  #   >> api('/issues', User.last)
  #   => "/api/v2/issues?private_token=..."
  #
  #   >> api('/issues?foo=bar', User.last)
  #   => "/api/v2/issues?foo=bar&private_token=..."
  #
  # Returns the relative path to the requested API resource
  def api(path, user = nil, version: API::API.version, personal_access_token: nil, oauth_access_token: nil, job_token: nil, access_token: nil, admin_mode: false)
    full_path = "/api/#{version}#{path}"

    if oauth_access_token
      query_string = "access_token=#{oauth_access_token.plaintext_token}"
    elsif personal_access_token
      query_string = "private_token=#{personal_access_token.token}"
    elsif job_token
      query_string = "job_token=#{job_token}"
    elsif access_token
      query_string = "access_token=#{access_token.token}"
    elsif user

      organization = Organizations::Organization.first || build(:organization)

      personal_access_token = if admin_mode && user.admin?
                                create(:personal_access_token, :admin_mode, user: user, organization: organization)
                              else
                                create(:personal_access_token, user: user, organization: organization)
                              end

      query_string = "private_token=#{personal_access_token.token}"
    end

    if query_string
      separator = path.index('?') ? '&' : '?'

      full_path + separator + query_string
    else
      full_path
    end
  end

  def expect_empty_array_response
    expect_successful_response_with_paginated_array
    expect(json_response.length).to eq(0)
  end

  def expect_successful_response_with_paginated_array
    expect(response).to have_gitlab_http_status(:ok)
    expect(response).to include_pagination_headers
    expect(json_response).to be_an Array
  end

  def expect_paginated_array_response(*items)
    expect(response).to have_gitlab_http_status(:ok)
    expect(response).to include_pagination_headers
    expect(json_response).to be_an Array
    expect(json_response.map { |item| item['id'] }).to eq(items.flatten)
  end

  def expect_response_contain_exactly(*items)
    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response).to be_an Array
    expect(json_response.map { |item| item['id'] }).to contain_exactly(*items)
  end

  def expect_paginated_array_response_contain_exactly(*items)
    expect(response).to have_gitlab_http_status(:ok)
    expect(response).to include_pagination_headers
    expect(json_response).to be_an Array
    expect(json_response.map { |item| item['id'] }).to contain_exactly(*items)
  end

  def stub_last_activity_update
    allow_next_instance_of(Users::ActivityService) do |service|
      allow(service).to receive(:execute)
    end
  end
end
