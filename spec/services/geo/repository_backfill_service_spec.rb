require 'spec_helper'

describe Geo::RepositoryBackfillService, services: true do
  SYSTEM_HOOKS_HEADER = { 'Content-Type' => 'application/json', 'X-Gitlab-Event' => 'System Hook' }.freeze

  let(:project) { create(:project) }
  let(:geo_node) { create(:geo_node) }

  subject { Geo::RepositoryBackfillService.new(project, geo_node) }

  describe '#execute' do
    it 'calls upon the system hook of the Geo Node' do
      WebMock.stub_request(:post, geo_node.geo_events_url)

      subject.execute

      expect(WebMock).to have_requested(:post, geo_node.geo_events_url).with(
        headers: SYSTEM_HOOKS_HEADER,
        body: {
          event_name: 'repository_update',
          project_id: project.id,
          project: project.hook_attrs,
          remote_url: project.ssh_url_to_repo
        }
      ).once
    end
  end
end
