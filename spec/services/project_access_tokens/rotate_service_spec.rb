# frozen_string_literal: true

require 'spec_helper'
RSpec.describe ProjectAccessTokens::RotateService, feature_category: :system_access do
  describe '#execute' do
    let_it_be(:token, reload: true) { create(:personal_access_token) }
    let(:current_user) { create(:user) }
    let(:project) { create(:project, group: create(:group)) }
    let(:error_message) { 'Not eligible to rotate token with access level higher than the user' }

    subject(:response) { described_class.new(current_user, token, project).execute }

    shared_examples_for 'rotates token succesfully' do
      it "rotates user's own token", :freeze_time do
        expect(response).to be_success

        new_token = response.payload[:personal_access_token]

        expect(new_token.token).not_to eq(token.token)
        expect(new_token.expires_at).to eq(Date.today + 1.week)
        expect(new_token.user).to eq(token.user)
      end
    end

    context 'when user tries to rotate token with different access level' do
      before do
        project.add_guest(token.user)
      end

      context 'when current user is an owner' do
        before do
          project.add_owner(current_user)
        end

        it_behaves_like "rotates token succesfully"

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

      context 'when current user is not an owner' do
        context 'when current user is maintainer' do
          before do
            project.add_maintainer(current_user)
          end

          context 'when access level is not owner' do
            it_behaves_like "rotates token succesfully"
          end

          context 'when access level is owner' do
            before do
              project.add_owner(token.user)
            end

            it "does not rotate token with higher priviledge" do
              response

              expect(response).to be_error
              expect(response.message).to eq(error_message)
            end
          end
        end

        context 'when current user is not maintainer' do
          before do
            project.add_developer(current_user)
          end

          it 'does not rotate the token' do
            response

            expect(response).to be_error
            expect(response.message).to eq(error_message)
          end
        end
      end

      context 'when current user is admin' do
        let(:current_user) { create(:admin) }

        context 'when admin mode enabled', :enable_admin_mode do
          it_behaves_like "rotates token succesfully"
        end

        context 'when admin mode not enabled' do
          it 'does not rotate the token' do
            response

            expect(response).to be_error
            expect(response.message).to eq(error_message)
          end
        end
      end

      context 'when nested membership' do
        let_it_be(:project_bot) { create(:user, :project_bot) }
        let(:token) { create(:personal_access_token, user: project_bot) }
        let(:top_level_group) { create(:group) }
        let(:sub_group) { create(:group, parent: top_level_group) }
        let(:project) { create(:project, group: sub_group) }

        before do
          project.add_maintainer(project_bot)
        end

        context 'when current user is an owner' do
          before do
            project.add_owner(current_user)
          end

          it_behaves_like "rotates token succesfully"

          context 'when its a bot user' do
            let_it_be(:bot_user) { create(:user, :project_bot) }
            let_it_be(:bot_user_membership) do
              create(:project_member, :developer, user: bot_user, project: create(:project))
            end

            let_it_be(:token, reload: true) { create(:personal_access_token, user: bot_user) }

            it 'updates membership expires at' do
              response

              new_token = response.payload[:personal_access_token]
              expect(bot_user_membership.reload.expires_at).to eq(new_token.expires_at)
            end
          end
        end

        context 'when current user is not an owner' do
          context 'when current user is maintainer' do
            before do
              project.add_maintainer(current_user)
            end

            context 'when access level is not owner' do
              it_behaves_like "rotates token succesfully"
            end

            context 'when access level is owner' do
              before do
                project.add_owner(token.user)
              end

              it "does not rotate token with higher priviledge" do
                response

                expect(response).to be_error
                expect(response.message).to eq(error_message)
              end
            end
          end

          context 'when current user is not maintainer' do
            before do
              project.add_developer(current_user)
            end

            it 'does not rotate the token' do
              response

              expect(response).to be_error
              expect(response.message).to eq(error_message)
            end
          end
        end
      end
    end
  end
end
