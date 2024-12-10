# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::HarborSerializers::RepositoryEntity, feature_category: :container_registry do
  let_it_be(:harbor_integration) { create(:harbor_integration) }

  let(:repo) do
    {
      "artifact_count" => 1,
      "creation_time" => "2022-03-13T09:36:43.240Z",
      "id" => 1,
      "name" => "jihuprivate/busybox",
      "project_id" => 4,
      "pull_count" => 0,
      "update_time" => "2022-03-13T09:36:43.240Z"
    }.deep_stringify_keys
  end

  subject { described_class.new(repo, url: "https://demo.goharbor.io", project_name: "jihuprivate").as_json }

  context 'with normal repository data' do
    it 'returns the Harbor repository' do
      expect(subject).to include({
        artifact_count: 1,
        creation_time: "2022-03-13T09:36:43.240Z".to_datetime,
        harbor_id: 1,
        name: "jihuprivate/busybox",
        harbor_project_id: 4,
        pull_count: 0,
        update_time: "2022-03-13T09:36:43.240Z".to_datetime,
        location: "https://demo.goharbor.io/harbor/projects/4/repositories/busybox"
      })
    end
  end

  context 'with data that may contain path traversal attacks' do
    before do
      repo["project_id"] = './../../../../../etc/hosts'
      repo['name'] = './../../../../../etc/hosts'
    end

    it 'logs an error and forbids the path traversal values' do
      expect(Gitlab::AppLogger).to receive(:error).with(/Path traversal attack detected/).twice

      expect(subject).to include({
        artifact_count: 1,
        creation_time: "2022-03-13T09:36:43.240Z".to_datetime,
        harbor_id: 1,
        name: '',
        harbor_project_id: './../../../../../etc/hosts',
        pull_count: 0,
        update_time: "2022-03-13T09:36:43.240Z".to_datetime,
        location: "https://demo.goharbor.io/"
      })
    end
  end
end
