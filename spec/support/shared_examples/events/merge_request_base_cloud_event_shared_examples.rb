# frozen_string_literal: true

RSpec.shared_examples 'a merge request base cloud event' do
  it 'sets event_category to :merge_requests' do
    expect(event.event_category).to eq(:merge_requests)
  end

  it 'includes base merge request fields in event_data' do
    expect(event.event_data).to include(
      merge_request_id: merge_request.id,
      merge_request_iid: merge_request.iid,
      project_id: merge_request.project_id
    )
  end

  it 'sets the CloudEvent source to the project' do
    expect(event.data[:source]).to eq("projects/#{merge_request.project.id}")
  end

  it 'sets the CloudEvent subject to the merge request' do
    expect(event.data[:subject]).to eq("merge_requests/#{merge_request.id}")
  end
end
