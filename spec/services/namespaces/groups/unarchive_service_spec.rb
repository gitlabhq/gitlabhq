# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Groups::UnarchiveService, '#execute', feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before_all do
    group.add_owner(user)
  end

  subject(:service_response) { described_class.new(group, user).execute }

  context 'when the group is already unarchived' do
    before do
      group.namespace_settings.update!(archived: false)
    end

    it 'returns an error' do
      expect(service_response).to be_error
      expect(service_response.message).to eq("Group is already unarchived!")
    end
  end

  context 'when the group is archived' do
    before do
      group.namespace_settings.update!(archived: true)
    end

    context 'when unarchiving succeeds' do
      before do
        allow(group).to receive(:unarchive).and_return(true)
      end

      it 'calls unarchive on the group' do
        expect(group).to receive(:unarchive).and_return(true)
        service_response
      end

      it 'updates associated projects' do
        projects = create_list(:project, 2, group: group)

        expect_next_instance_of(GroupProjectsFinder,
          hash_including(current_user: user, group: group)) do |group_projects_finder|
          expect(group_projects_finder).to receive(:execute).and_return(projects)
        end

        projects.each do |project|
          expect_next_instances_of(::Projects::UpdateService, 1, true, project, user,
            archived: false) do |project_update_service|
            expect(project_update_service).to receive(:execute).and_return(true)
          end
        end

        service_response
      end

      it 'returns a success response with the group' do
        expect(service_response).to be_success
      end
    end

    context 'when unarchiving fails' do
      before do
        allow(group).to receive(:unarchive).and_return(false)
      end

      it 'returns an error response with the appropriate message' do
        response = service_response
        expect(response).to be_error
        expect(response.message).to eq("Failed to unarchive group!")
      end
    end

    context 'when project update fails' do
      let_it_be(:failing_project) { create(:project, group: group) }

      before do
        allow(group).to receive(:unarchive).and_return(true)
      end

      it 'unarchiving fails and raises an UpdateError' do
        expect_next_instance_of(GroupProjectsFinder, hash_including(current_user: user, group: group)) do |finder|
          expect(finder).to receive(:execute).and_return([failing_project])
        end

        expect_next_instance_of(::Projects::UpdateService, failing_project, user, archived: false) do |update_service|
          expect(update_service).to receive(:execute).and_return(false)
        end

        expect { service_response }
          .to raise_error(described_class::UpdateError, "Project #{failing_project.id} can't be unarchived!")
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
