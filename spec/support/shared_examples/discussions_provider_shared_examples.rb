# frozen_string_literal: true

require 'spec_helper'

shared_examples 'discussions provider' do
  it 'returns the expected discussions' do
    get :discussions, params: { namespace_id: project.namespace, project_id: project, id: requested_iid }

    expect(response).to have_gitlab_http_status(200)
    expect(response).to match_response_schema('entities/discussions')

    expect(json_response.size).to eq(expected_discussion_count)
    expect(json_response.pluck('id')).to eq(expected_discussion_ids)
  end
end
