# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::Concerns::OrganizationUpdater, feature_category: :cell do
  let(:test_class) do
    Class.new do
      include Organizations::Concerns::OrganizationUpdater

      attr_reader :old_organization, :new_organization

      def initialize(old_org, new_org)
        @old_organization = old_org
        @new_organization = new_org
      end
    end
  end

  let_it_be(:old_organization) { create(:organization) }
  let_it_be(:new_organization) { create(:organization) }
  let(:service) { test_class.new(old_organization, new_organization) }

  describe '#update_organization_id_for' do
    context 'without block' do
      let_it_be(:user1) { create(:user, organization: old_organization) }
      let_it_be(:user2) { create(:user, organization: old_organization) }
      let_it_be(:user3) { create(:user, organization: new_organization) }

      let_it_be(:token1) do
        create(:personal_access_token, user: user1, organization: old_organization)
      end

      let_it_be(:token2) do
        create(:personal_access_token, user: user2, organization: old_organization)
      end

      let_it_be(:token3) do
        create(:personal_access_token, user: user3, organization: new_organization)
      end

      it 'updates all records in old organization when no block is provided' do
        service.update_organization_id_for(PersonalAccessToken)

        expect(token1.reload.organization_id).to eq(new_organization.id)
        expect(token2.reload.organization_id).to eq(new_organization.id)
        expect(token3.reload.organization_id).to eq(new_organization.id)
      end
    end

    context 'with empty scope' do
      it 'does not perform any updates when scope results in no records' do
        service.update_organization_id_for(PersonalAccessToken) { |relation| relation.where(user_id: []) }

        expect(PersonalAccessToken.where(organization_id: new_organization.id)).to be_empty
      end
    end

    context 'with valid scope' do
      let_it_be(:user1) { create(:user, organization: old_organization) }
      let_it_be(:user2) { create(:user, organization: old_organization) }
      let_it_be(:user3) { create(:user, organization: new_organization) }

      let_it_be(:token1) do
        create(:personal_access_token, user: user1, organization: old_organization)
      end

      let_it_be(:token2) do
        create(:personal_access_token, user: user2, organization: old_organization)
      end

      let_it_be(:token3) do
        create(:personal_access_token, user: user3, organization: new_organization)
      end

      it 'updates organization_id for records matching scope and old organization' do
        service.update_organization_id_for(PersonalAccessToken) do |relation|
          relation.where(user_id: [user1.id, user2.id])
        end

        expect(token1.reload.organization_id).to eq(new_organization.id)
        expect(token2.reload.organization_id).to eq(new_organization.id)
      end

      it 'does not update records not matching scope' do
        service.update_organization_id_for(PersonalAccessToken) do |relation|
          relation.where(user_id: [user1.id])
        end

        expect(token1.reload.organization_id).to eq(new_organization.id)
        expect(token2.reload.organization_id).to eq(old_organization.id)
      end

      it 'does not update records already in new organization' do
        service.update_organization_id_for(PersonalAccessToken) do |relation|
          relation.where(user_id: [user1.id, user2.id, user3.id])
        end

        expect(token3.reload.organization_id).to eq(new_organization.id)
        expect(token3.reload.updated_at).to eq(token3.created_at)
      end
    end

    context 'with batching' do
      let_it_be(:user1) { create(:user, organization: old_organization) }
      let_it_be(:user2) { create(:user, organization: old_organization) }
      let_it_be(:user3) { create(:user, organization: old_organization) }

      let_it_be(:token1) { create(:personal_access_token, user: user1, organization: old_organization) }
      let_it_be(:token2) { create(:personal_access_token, user: user2, organization: old_organization) }
      let_it_be(:token3) { create(:personal_access_token, user: user3, organization: old_organization) }

      it 'processes records in batches' do
        stub_const("#{described_class}::ORGANIZATION_ID_UPDATE_BATCH_SIZE", 1)

        service.update_organization_id_for(PersonalAccessToken) do |relation|
          relation.where(user_id: [user1.id, user2.id, user3.id])
        end

        expect(token1.reload.organization_id).to eq(new_organization.id)
        expect(token2.reload.organization_id).to eq(new_organization.id)
        expect(token3.reload.organization_id).to eq(new_organization.id)
      end
    end

    context 'with complex scopes' do
      let_it_be(:user1) { create(:user, organization: old_organization) }
      let_it_be(:active_token) do
        create(:personal_access_token, user: user1, organization: old_organization, revoked: false)
      end

      let_it_be(:revoked_token) do
        create(:personal_access_token, user: user1, organization: old_organization, revoked: true)
      end

      it 'applies complex scope with multiple conditions' do
        service.update_organization_id_for(PersonalAccessToken) do |relation|
          relation.where(user_id: [user1.id], revoked: false)
        end

        expect(active_token.reload.organization_id).to eq(new_organization.id)
        expect(revoked_token.reload.organization_id).to eq(old_organization.id)
      end

      it 'supports using model scopes' do
        service.update_organization_id_for(PersonalAccessToken) do |relation|
          relation.where(user_id: [user1.id]).not_revoked
        end

        expect(active_token.reload.organization_id).to eq(new_organization.id)
        expect(revoked_token.reload.organization_id).to eq(old_organization.id)
      end
    end

    context 'with different models' do
      let_it_be(:project) { create(:project, organization: old_organization) }
      let_it_be(:note1) { create(:note, project: project) }
      let_it_be(:note2) { create(:note, project: project) }

      before do
        # Manually set organization_id since Note might not have organization= setter
        Note.where(id: [note1.id, note2.id]).update_all(organization_id: old_organization.id)
      end

      it 'works with different models and scope columns' do
        service.update_organization_id_for(Note) do |relation|
          relation.where(project_id: [project.id])
        end

        expect(note1.reload.organization_id).to eq(new_organization.id)
        expect(note2.reload.organization_id).to eq(new_organization.id)
      end
    end
  end
end
