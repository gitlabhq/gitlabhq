# frozen_string_literal: true

require 'spec_helper'
RSpec.describe ProjectAccessTokens::RotateService, feature_category: :system_access do
  describe '#execute' do
    let(:token) { create(:resource_access_token, resource: project) }
    let(:current_user) { create(:user) }
    let(:project) { create(:project, group: create(:group)) }
    let(:error_message) { 'Not eligible to rotate tokens with permissions not held by the user' }

    subject(:response) { described_class.new(current_user, token, project).execute }

    shared_examples_for 'rotates token successfully' do
      it "rotates user's own token", :freeze_time do
        expect(token.user_type).not_to be_nil
        expect(response).to be_success

        new_token = response.payload[:personal_access_token]

        expect(new_token.token).not_to eq(token.token)
        expect(new_token.expires_at).to eq(1.week.from_now.to_date)
        expect(new_token.user).to eq(token.user)
        expect(new_token.user_type).to eq(token.user_type)
        expect(new_token.group).to eq(token.group)
      end

      it_behaves_like 'internal event tracking' do
        let(:event) { 'rotate_prat' }
        let(:category) { described_class.name }
        let(:user) { token.user }
        let(:namespace) { project.namespace }
        subject(:track_event) { response }
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

        it_behaves_like "rotates token successfully"

        context 'when creating the new token fails' do
          before do
            # change the default expiration for rotation to create an invalid token
            stub_const('::PersonalAccessTokens::RotateService::EXPIRATION_PERIOD', 10.years)
          end

          it 'returns an error' do
            expect(response).to be_error
            expect(response.message).to include('Expiration date must be before')
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
            it_behaves_like "rotates token successfully"
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
          it_behaves_like "rotates token successfully"
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

          it_behaves_like "rotates token successfully"

          context 'when its a bot user' do
            let_it_be(:bot_user) { create(:user, :project_bot) }
            let_it_be(:token, reload: true) { create(:personal_access_token, user: bot_user) }
            let_it_be(:bot_user_membership) do
              create(
                :project_member,
                :developer,
                user: bot_user,
                project: create(:project),
                expires_at: token.expires_at
              )
            end

            it 'does not set membership expires at' do
              response
              expect(bot_user_membership.reload.expires_at).to be_nil
            end
          end
        end

        context 'when current user is not an owner' do
          context 'when current user is maintainer' do
            before do
              project.add_maintainer(current_user)
            end

            context 'when access level is not owner' do
              it_behaves_like "rotates token successfully"
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

    context 'for token external status inheritance from current_user' do
      context 'when current user is maintainer' do
        before do
          project.add_maintainer(current_user)
        end

        context 'when current_user is external and token is not external' do
          before do
            current_user.update!(external: true)
          end

          it 'rotates token and token inherits current_user external status', :aggregate_failures do
            expect(current_user.external).to be(true)
            expect(token.user.external).to be(false)

            expect(response).to be_success

            new_token = response.payload[:personal_access_token]
            expect(new_token.user).to eq(token.user)

            expect(current_user.external).to be(true)
            expect(new_token.user.external).to be(true)
          end
        end

        context 'when current_user is not external and token is external' do
          before do
            token.user.update!(external: true)
          end

          it 'rotates token and token inherits current_user external status', :aggregate_failures do
            expect(current_user.external).to be(false)
            expect(token.user.external).to be(true)

            expect(response).to be_success

            new_token = response.payload[:personal_access_token]
            expect(new_token.user).to eq(token.user)

            expect(current_user.external).to be(false)
            expect(new_token.user.external).to be(false)
          end
        end
      end
    end
  end
end
