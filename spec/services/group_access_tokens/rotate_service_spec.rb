# frozen_string_literal: true

require 'spec_helper'
RSpec.describe GroupAccessTokens::RotateService, feature_category: :system_access do
  describe '#execute' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:token, reload: true) { create(:personal_access_token, user: create(:user, :project_bot)) }
    let_it_be(:group) { create(:group) }
    let_it_be(:bot_user_membership) { create(:group_member, :developer, user: token.user, group: group) }

    subject(:response) { described_class.new(current_user, token, group).execute }

    shared_examples_for 'rotates the token successfully' do
      it 'rotates the token and does not set the bot user expires at', :freeze_time do
        expect(response).to be_success

        new_token = response.payload[:personal_access_token]

        expect(new_token.token).not_to eq(token.token)
        expect(new_token.expires_at).to eq(1.week.from_now.to_date)
        expect(new_token.user).to eq(token.user)
        expect(bot_user_membership.reload.expires_at).to be_nil
      end
    end

    shared_examples_for 'fails to rotate the token' do
      it 'does not rotate the token' do
        response

        expect(response).to be_error
        expect(response.message).to eq('Not eligible to rotate token with access level higher than the user')
      end
    end

    context 'when the user is an admin', :enable_admin_mode do
      let(:current_user) { create(:admin) }

      it_behaves_like 'rotates the token successfully'
    end

    context 'when the user is an owner' do
      before_all do
        group.add_owner(current_user)
      end

      it_behaves_like 'rotates the token successfully'
    end

    context 'when the user is not an owner' do
      before_all do
        group.add_maintainer(current_user)
      end

      it_behaves_like 'fails to rotate the token'

      context 'when the user has the `manage_resource_access_tokens` ability' do
        before do
          allow(current_user).to receive(:can?).and_call_original
          allow(current_user).to receive(:can?).with(:manage_resource_access_tokens, group).and_return(true)
        end

        it_behaves_like 'rotates the token successfully'

        context 'when the user has an access level lower than the token access level' do
          before_all do
            group.add_guest(current_user)
          end

          it_behaves_like 'fails to rotate the token'
        end
      end
    end
  end
end
