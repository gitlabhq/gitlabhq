# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::Transfer::Concerns::OrganizationUpdater, feature_category: :cell do
  let(:test_class) do
    Class.new do
      include Organizations::Transfer::Concerns::OrganizationUpdater

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

      it 'selects batches without ORDER BY and updates each batch once' do
        stub_const("#{described_class}::ORGANIZATION_ID_UPDATE_BATCH_SIZE", 1)

        recorder = ActiveRecord::QueryRecorder.new do
          service.update_organization_id_for(PersonalAccessToken) do |relation|
            relation.where(user_id: [user1.id, user2.id, user3.id])
          end
        end

        selects = recorder.log.select do |query|
          query.include?('SELECT "personal_access_tokens"."id" FROM "personal_access_tokens"')
        end
        updates = recorder.log.select { |query| query.include?('UPDATE "personal_access_tokens"') }

        expect(selects.size).to eq(4)
        expect(selects).to all(exclude('ORDER BY'))
        expect(updates.size).to eq(3)
      end
    end

    context 'when old and new organization are the same' do
      let(:service) { test_class.new(old_organization, old_organization) }

      it 'raises an error' do
        expect { service.update_organization_id_for(PersonalAccessToken) }
          .to raise_error(ArgumentError, 'old and new organization must differ')
      end
    end

    context 'when the block does not narrow by organization' do
      let_it_be(:user1) { create(:user, organization: old_organization) }
      let_it_be(:token1) { create(:personal_access_token, user: user1, organization: old_organization) }

      it 'stops once the plucked ids no longer move' do
        recorder = ActiveRecord::QueryRecorder.new do
          service.update_organization_id_for(PersonalAccessToken) do |relation|
            relation.unscope(where: :organization_id).where(user_id: user1.id)
          end
        end

        expect(token1.reload.organization_id).to eq(new_organization.id)
        expect(recorder.log.count { |query| query.include?('UPDATE "personal_access_tokens"') }).to eq(1)
      end
    end

    context 'when the block selects a row in another organization' do
      let_it_be(:other_organization) { create(:organization) }
      let_it_be(:user1) { create(:user, organization: other_organization) }
      let_it_be(:token1) { create(:personal_access_token, user: user1, organization: other_organization) }

      it 'leaves the row in place and stops after the first pluck' do
        recorder = ActiveRecord::QueryRecorder.new do
          service.update_organization_id_for(PersonalAccessToken) do |relation|
            relation.unscope(where: :organization_id).where(user_id: user1.id)
          end
        end

        selects = recorder.log.select do |query|
          query.include?('SELECT "personal_access_tokens"."id" FROM "personal_access_tokens"')
        end

        expect(token1.reload.organization_id).to eq(other_organization.id)
        expect(selects.size).to eq(1)
      end
    end

    context 'with a partitioned table', if: Gitlab.ee? do
      let_it_be(:user1) { create(:user, :with_namespace, organization: old_organization) }
      let_it_be(:user2) { create(:user, :with_namespace, organization: old_organization) }
      let_it_be(:current_event) { create(:ai_usage_event, user: user1, timestamp: Time.current) }
      let_it_be(:previous_month_event) { create(:ai_usage_event, user: user1, timestamp: 1.month.ago) }
      let_it_be(:other_user_event) { create(:ai_usage_event, user: user2, timestamp: Time.current) }

      it 'updates matching rows across partitions' do
        stub_const("#{described_class}::ORGANIZATION_ID_UPDATE_BATCH_SIZE", 1)

        recorder = ActiveRecord::QueryRecorder.new do
          service.update_organization_id_for(Ai::UsageEvent) { |relation| relation.where(user_id: user1.id) }
        end

        updates = recorder.log.select { |query| query.include?('UPDATE "ai_usage_events"') }

        expect(updates.size).to eq(2)
        expect(updates).to all(include('"ai_usage_events"."timestamp"'))
        expect(Ai::UsageEvent.where(id: [current_event.id, previous_month_event.id]).pluck(:organization_id))
          .to all(eq(new_organization.id))
        expect(Ai::UsageEvent.find_by(id: other_user_event.id).organization_id).to eq(old_organization.id)
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
      let_it_be(:author) { create(:user, organization: old_organization) }
      let_it_be(:snippet, freeze: false) { create(:personal_snippet, author: author, organization: old_organization) }
      let_it_be(:note1) { create(:note_on_personal_snippet, noteable: snippet) }
      let_it_be(:note2) { create(:note_on_personal_snippet, noteable: snippet) }

      before do
        # Manually set organization_id since Note might not have organization= setter
        Note.where(id: [note1.id, note2.id]).update_all(organization_id: old_organization.id)
      end

      it 'works with different models and scope columns' do
        service.update_organization_id_for(Note) do |relation|
          relation.where(id: [note1.id, note2.id])
        end

        expect(note1.reload.organization_id).to eq(new_organization.id)
        expect(note2.reload.organization_id).to eq(new_organization.id)
      end
    end

    context 'with custom organization_key' do
      let_it_be(:user1) { create(:user, organization: old_organization) }
      let_it_be(:user2) { create(:user, organization: old_organization) }
      let_it_be(:snippet1) { create(:personal_snippet, author: user1, organization: old_organization) }
      let_it_be(:snippet2) { create(:personal_snippet, author: user2, organization: old_organization) }
      let_it_be(:new_org_snippet) { create(:personal_snippet, author: user1, organization: new_organization) }

      let_it_be(:repo1) { create(:snippet_repository, snippet: snippet1) }
      let_it_be(:repo2) { create(:snippet_repository, snippet: snippet2) }
      let_it_be(:new_org_repo) { create(:snippet_repository, snippet: new_org_snippet) }

      it 'updates records using the custom organization key column' do
        service.update_organization_id_for(SnippetRepository, organization_key: :snippet_organization_id)

        expect(repo1.reload.snippet_organization_id).to eq(new_organization.id)
        expect(repo2.reload.snippet_organization_id).to eq(new_organization.id)
      end

      it 'does not update records in other organizations' do
        service.update_organization_id_for(SnippetRepository, organization_key: :snippet_organization_id)

        expect(new_org_repo.reload.snippet_organization_id).to eq(new_organization.id)
      end

      it 'works with a block scope and custom key' do
        service.update_organization_id_for(SnippetRepository, organization_key: :snippet_organization_id) do |relation|
          relation.where(snippet_id: snippet1.id)
        end

        expect(repo1.reload.snippet_organization_id).to eq(new_organization.id)
        expect(repo2.reload.snippet_organization_id).to eq(old_organization.id)
      end
    end
  end
end
