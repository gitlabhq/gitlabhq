# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceAccessTokens::RotateService, feature_category: :system_access do
  shared_examples_for 'rotates token successfully' do
    it "rotates user's own token", :freeze_time do
      expect(response).to be_success

      new_token = response.payload[:personal_access_token]

      expect(new_token.token).not_to eq(token.token)
      expect(new_token.expires_at).to eq(Date.today + 1.week)
      expect(new_token.user).to eq(token.user)
    end

    it 'updates membership expires_at' do
      response

      new_token = response.payload[:personal_access_token]
      expect(bot_user.members.first.reload.expires_at).to eq(new_token.expires_at)
    end
  end

  shared_examples 'token rotation access level check' do |source_type|
    before do
      resource.add_guest(token.user)
    end

    context 'when current user is an owner' do
      before do
        resource.add_owner(current_user)
      end

      it_behaves_like "rotates token successfully"

      context 'when creating the new token fails' do
        let(:error_message) { 'boom!' }

        before do
          allow_next_instance_of(PersonalAccessToken) do |token|
            allow(token).to receive_message_chain(:errors, :full_messages, :to_sentence).and_return(error_message)
            allow(token).to receive_message_chain(:errors, :clear)
            allow(token).to receive_message_chain(:errors, :empty?).and_return(false)
          end
        end

        it 'returns an error' do
          expect(response).to be_error
          expect(response.message).to eq(error_message)
        end

        it 'reverts the changes' do
          expect { response }.not_to change { token.reload.revoked? }.from(false)
        end
      end
    end

    context 'when current user is maintainer' do
      before do
        resource.add_maintainer(current_user)
      end

      context 'and token user is not owner' do
        if source_type == 'project'
          it_behaves_like "rotates token successfully"
        elsif source_type == 'group'
          it 'cannot rotate the token' do
            response

            expect(response).to be_error
            expect(response.message).to eq(error_message)
          end
        end
      end

      context 'and token user is owner' do
        before do
          resource.add_owner(token.user)
        end

        it "cannot rotate token with higher privilege" do
          response

          expect(response).to be_error
          expect(response.message).to eq(error_message)
        end
      end
    end

    context 'when current user is neither owner or maintainer' do
      before do
        resource.add_developer(current_user)
      end

      it 'cannot rotate the token' do
        response

        expect(response).to be_error
        expect(response.message).to eq(error_message)
      end
    end

    context 'when current user is admin' do
      let(:current_user) { create(:admin) }

      context 'with admin mode', :enable_admin_mode do
        it_behaves_like "rotates token successfully"
      end

      context 'without admin mode' do
        it 'cannot rotate the token' do
          response

          expect(response).to be_error
          expect(response.message).to eq(error_message)
        end
      end
    end
  end

  describe '#execute' do
    subject(:response) { described_class.new(current_user, token, resource).execute }

    let(:current_user) { create(:user) }
    let(:error_message) { 'Not eligible to rotate token with access level higher than the user' }
    let(:bot_user) { create(:user, :project_bot) }
    let(:token) { create(:personal_access_token, user: bot_user) }

    context 'for project' do
      let_it_be(:resource) { create(:project, group: create(:group)) }

      it_behaves_like 'token rotation access level check', 'project'

      context 'with a nested membership' do
        let(:top_level_group) { create(:group) }
        let(:sub_group) { create(:group, parent: top_level_group) }
        let(:resource) { create(:project, group: sub_group) }

        it_behaves_like 'token rotation access level check', 'project'
      end
    end

    context 'for group' do
      let(:resource) { create(:group) }

      it_behaves_like 'token rotation access level check', 'group'

      context 'with a nested membership' do
        let(:top_level_group) { create(:group) }
        let(:resource) { create(:group, parent: top_level_group) }

        it_behaves_like 'token rotation access level check', 'group'
      end
    end
  end
end
