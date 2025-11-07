# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Groups::ArchiveService, '#execute', feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before_all do
    group.add_owner(user)
  end

  subject(:service_response) { described_class.new(group, user).execute }

  context 'when the user does not have permission to archive the group' do
    let(:user) { nil }

    it 'returns an error response' do
      expect(service_response).to be_error
      expect(service_response.message).to eq("You don't have permissions to archive this group!")
    end
  end

  context 'when the archive_group feature flag is disabled' do
    before do
      stub_feature_flags(archive_group: false)
    end

    it 'returns an error response' do
      expect(service_response).to be_error
      expect(service_response.message).to eq("You don't have permissions to archive this group!")
    end
  end

  context 'when the group is already archived' do
    before do
      group.namespace_settings.update!(archived: true)
    end

    it 'returns an error response' do
      expect(service_response).to be_error
      expect(service_response.message).to eq("Group is already archived!")
    end
  end

  context 'when ancestor group is already archived' do
    let_it_be(:parent) { create(:group) }
    let_it_be(:group) { create(:group, parent: parent) }
    let_it_be(:user) { create(:user) }

    before_all do
      group.add_owner(user)
      parent.update!(archived: true)
    end

    it 'returns an error response' do
      expect(service_response).to be_error
      expect(service_response.message)
        .to eq("Cannot archive group since one of the ancestor groups is already archived!")
    end
  end

  context 'when the group is not archived' do
    before do
      group.namespace_settings.update!(archived: false)
    end

    context 'when archiving succeeds' do
      it 'calls archive on the group' do
        expect(group).to receive(:archive).and_return(true)
        service_response
      end

      it 'returns a success response with the group' do
        expect(service_response).to be_success
      end

      it 'publishes a GroupArchivedEvent' do
        expect { service_response }.to publish_event(Namespaces::Groups::GroupArchivedEvent)
                                        .with(
                                          group_id: group.id,
                                          root_namespace_id: group.root_ancestor.id
                                        )
      end

      context 'when destroy_fork_network_on_group_archive feature flag is enabled' do
        let_it_be(:project1) { create(:project, namespace: group) }
        let_it_be(:project2) { create(:project, namespace: group) }

        before do
          stub_feature_flags(destroy_fork_network_on_group_archive: true)
        end

        it 'enqueues UnlinkProjectForksWorker' do
          expect(Namespaces::UnlinkProjectForksWorker)
            .to receive(:perform_async).with(group.id, user.id)

          service_response
        end
      end

      context 'when destroy_fork_network_on_group_archive feature flag is disabled' do
        let_it_be(:project) { create(:project, namespace: group) }

        before do
          stub_feature_flags(destroy_fork_network_on_group_archive: false)
        end

        it 'does not enqueue UnlinkProjectForksWorker' do
          expect(Namespaces::UnlinkProjectForksWorker).not_to receive(:perform_async)

          service_response
        end
      end
    end

    context 'when archiving fails' do
      before do
        allow(group).to receive(:archive).and_return(false)
      end

      it 'returns an error response with the appropriate message' do
        response = service_response
        expect(response).to be_error
        expect(response.message).to eq("Failed to archive group!")
      end
    end
  end

  describe "#error_response" do
    subject(:error_response_result) { described_class.new(group, user).send(:error_response, "Test error message") }

    it "returns a service response error" do
      expect(error_response_result).to be_error
      expect(error_response_result.message).to eq("Test error message")
    end
  end
end
