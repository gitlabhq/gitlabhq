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

  context 'when ancestor group is archived' do
    let_it_be(:parent) { create(:group) }
    let_it_be(:group) { create(:group, parent: parent) }
    let_it_be(:user) { create(:user) }

    before_all do
      group.add_owner(user)
      parent.update!(archived: true)
    end

    it 'returns an error response' do
      expect(service_response).to be_error
      expect(service_response.message).to eq("Cannot unarchive group since one of the ancestor groups is archived!")
    end
  end

  context 'when the group is archived' do
    let_it_be_with_reload(:subgroup) { create(:group, :archived, parent: group) }
    let_it_be_with_reload(:sub_subgroup) { create(:group, :archived, parent: subgroup) }

    let_it_be_with_reload(:archived_project) { create(:project, :archived, group: group) }
    let_it_be_with_reload(:archived_subgroup_project) { create(:project, :archived, group: subgroup) }

    before do
      group.namespace_settings.update!(archived: true)
    end

    shared_examples 'rolls back all changes on failure' do
      let(:error_message) { 'random error message' }

      before do
        allow(group).to receive(:unarchive!)

        errors = ActiveModel::Errors.new(group).tap { |e| e.add(:base, error_message) }
        allow(group).to receive(:errors).and_return(errors)
      end

      it 'returns an error response' do
        response = service_response
        expect(response).to be_error
        expect(response.message).to eq("Failed to unarchive group! #{error_message}")
      end

      it 'does not persist any changes' do
        expect { service_response }
          .to not_change { group.namespace_settings.reload.archived }
            .and not_change { subgroup.namespace_settings.reload.archived }
              .and not_change { archived_project.reload.archived }
      end
    end

    context 'when unarchiving succeeds' do
      it 'updates the namespace state' do
        service_response

        expect(group.state).to be(Namespaces::Stateful::STATES[:ancestor_inherited])
      end

      it 'unarchives all descendant groups', :aggregate_failures do
        service_response

        expect(group.namespace_settings.reload.archived).to be(false)
        expect(subgroup.namespace_settings.reload.archived).to be(false)
        expect(sub_subgroup.namespace_settings.reload.archived).to be(false)
      end

      it 'unarchives all projects', :aggregate_failures do
        service_response

        expect(archived_project.reload.archived).to be(false)
        expect(archived_subgroup_project.reload.archived).to be(false)
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

      context 'when `cascade_unarchive_group` flag is disabled' do
        before do
          stub_feature_flags(cascade_unarchive_group: false)
        end

        it 'unarchives the group' do
          service_response

          expect(group.namespace_settings.reload.archived).to be(false)
        end

        it 'does not modify descendant and projects archived state' do
          expect { service_response }
            .to not_change { subgroup.namespace_settings.reload.archived }
              .and not_change { sub_subgroup.namespace_settings.reload.archived }
                .and not_change { archived_project.reload.archived }
                  .and not_change { archived_subgroup_project.reload.archived }
        end
      end
    end

    context 'when unarchiving fails' do
      before do
        allow(group).to receive(:unarchive_descendants!).and_raise(ActiveRecord::RecordNotSaved)
      end

      it_behaves_like 'rolls back all changes on failure'
    end

    context 'when unarchiving projects fails' do
      before do
        allow(group).to receive(:unarchive_all_projects!).and_raise(ActiveRecord::RecordNotSaved)
      end

      it_behaves_like 'rolls back all changes on failure'
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
