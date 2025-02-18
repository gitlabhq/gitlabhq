# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceAccessTokens::RevokeService, feature_category: :system_access do
  subject { described_class.new(user, resource, access_token).execute }

  let_it_be(:user) { create(:user) }
  let_it_be(:user_non_priviledged) { create(:user) }
  let_it_be(:resource_bot) { create(:user, :project_bot) }

  let(:access_token) { create(:personal_access_token, user: resource_bot) }

  describe '#execute', :sidekiq_inline do
    shared_examples 'revokes access token' do
      it { expect(subject.success?).to be true }

      it { expect(subject.message).to eq("Access token #{access_token.name} has been revoked.") }

      it 'does not call the delete user worker' do
        expect(DeleteUserWorker).not_to receive(:perform_async)

        subject
      end

      it 'bot user retains membership' do
        subject

        expect(resource.reload).to have_user(resource_bot)
      end

      it 'logs the event' do
        allow(Gitlab::AppLogger).to receive(:info)

        subject

        expect(Gitlab::AppLogger).to have_received(:info).with("PROJECT ACCESS TOKEN REVOCATION: revoked_by: #{user.username}, project_id: #{resource.id}, token_user: #{resource_bot.name}, token_id: #{access_token.id}")
      end
    end

    shared_examples 'rollback revoke steps' do
      it 'does not revoke the access token' do
        subject

        expect(access_token.reload.revoked?).to be false
      end

      it 'does not remove bot from member list' do
        subject

        expect(resource.reload).to have_user(resource_bot)
      end

      it 'does not transfer issuables of bot user to ghost user' do
        issue = create(:issue, author: resource_bot)

        subject

        expect(issue.reload.author.ghost?).to be false
      end

      it 'does not destroy project bot user' do
        subject

        expect(User.exists?(resource_bot.id)).to be_truthy
      end
    end

    shared_examples 'revoke fails' do |resource_type|
      let_it_be(:other_user) { create(:user) }

      context "when access token does not belong to this #{resource_type}" do
        it 'does not find the bot' do
          other_access_token = create(:personal_access_token, user: other_user)

          response = described_class.new(user, resource, other_access_token).execute

          expect(response.success?).to be false
          expect(response.message).to eq("Failed to find bot user")
          expect(access_token.reload.revoked?).to be false
        end
      end

      context 'when user does not have permission to destroy bot' do
        context "when non-#{resource_type} member tries to delete project bot" do
          it 'does not allow other user to delete bot' do
            response = described_class.new(other_user, resource, access_token).execute

            expect(response.success?).to be false
            expect(response.message).to eq("#{other_user.name} cannot delete #{access_token.user.name}")
            expect(access_token.reload.revoked?).to be false
          end
        end

        context "when non-priviledged #{resource_type} member tries to delete project bot" do
          it 'does not allow developer to delete bot' do
            response = described_class.new(user_non_priviledged, resource, access_token).execute

            expect(response.success?).to be false
            expect(response.message).to eq("#{user_non_priviledged.name} cannot delete #{access_token.user.name}")
            expect(access_token.reload.revoked?).to be false
          end
        end
      end

      context 'when deletion of bot user fails' do
        before do
          allow_next_instance_of(::ResourceAccessTokens::RevokeService) do |service|
            allow(service).to receive(:execute).and_return(false)
          end
        end

        it_behaves_like 'rollback revoke steps'
      end
    end

    context 'when resource is a project' do
      let_it_be(:resource) { create(:project, :private) }

      before do
        resource.add_maintainer(user)
        resource.add_developer(user_non_priviledged)
        resource.add_maintainer(resource_bot)
      end

      it_behaves_like 'revokes access token'

      it_behaves_like 'revoke fails', 'project'
    end

    context 'when resource is a group' do
      let_it_be(:resource) { create(:group, :private) }

      before do
        resource.add_owner(user)
        resource.add_maintainer(user_non_priviledged)
        resource.add_maintainer(resource_bot)
      end

      it_behaves_like 'revokes access token'

      it_behaves_like 'revoke fails', 'group'
    end
  end
end
