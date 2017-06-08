require 'spec_helper'

describe PostReceive do
  let(:changes) { "123456 789012 refs/heads/tést\n654321 210987 refs/tags/tag" }
  let(:wrongly_encoded_changes) { changes.encode("ISO-8859-1").force_encoding("UTF-8") }
  let(:base64_changes) { Base64.encode64(wrongly_encoded_changes) }
  let(:project_identifier) { "project-#{project.id}" }
  let(:key) { create(:key, user: project.owner) }
  let(:key_id) { key.shell_id }
  let(:project) { create(:project, :repository) }

  describe "#process_project_changes" do
    before do
      allow_any_instance_of(Gitlab::GitPostReceive).to receive(:identify).and_return(project.owner)
    end

    context 'after project changes hooks' do
      let(:fake_hook_data) { Hash.new(event_name: 'repository_update') }

      before do
        allow_any_instance_of(Gitlab::DataBuilder::Repository).to receive(:update).and_return(fake_hook_data)
        # silence hooks so we can isolate
        allow_any_instance_of(Key).to receive(:post_create_hook).and_return(true)
        allow_any_instance_of(GitTagPushService).to receive(:execute).and_return(true)
        allow_any_instance_of(GitPushService).to receive(:execute).and_return(true)
      end

      it 'calls Geo::RepositoryUpdatedEventStore' do
        expect_any_instance_of(Geo::RepositoryUpdatedEventStore).to receive(:create)

        described_class.new.perform(project_identifier, key_id, base64_changes)
      end
    end
  end

  describe '#process_wiki_changes' do
    let(:project_identifier) { "#{pwd(project)}.wiki" }

    it 'triggers Geo::RepositoryUpdatedEventStore when Geo is enabled' do
      allow(Gitlab::Geo).to receive(:enabled?) { true }

      expect(Geo::RepositoryUpdatedEventStore).to receive(:new).with(instance_of(Project), source: Geo::RepositoryUpdatedEvent::WIKI).and_call_original
      expect_any_instance_of(Geo::RepositoryUpdatedEventStore).to receive(:create)

      described_class.new.perform(project_identifier, key_id, base64_changes)
    end

    it 'triggers wiki index update when ElasticSearch is enabled' do
      expect(Project).to receive(:find_by_full_path).with("#{project.full_path}.wiki").and_return(nil)
      expect(Project).to receive(:find_by_full_path).with(project.full_path).and_return(project)
      stub_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

      expect_any_instance_of(ProjectWiki).to receive(:index_blobs)

      described_class.new.perform(project_identifier, key_id, base64_changes)
    end
  end

  def pwd(project)
    File.join(Gitlab.config.repositories.storages.default['path'], project.path_with_namespace)
  end
end
