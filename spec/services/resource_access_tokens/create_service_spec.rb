# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceAccessTokens::CreateService do
  subject { described_class.new(user, resource, params).execute }

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:params) { {} }

  describe '#execute' do
    # Created shared_examples as it will easy to include specs for group bots in https://gitlab.com/gitlab-org/gitlab/-/issues/214046
    shared_examples 'token creation fails' do
      let(:resource) { create(:project)}

      it 'does not add the project bot as a member' do
        expect { subject }.not_to change { resource.members.count }
      end

      it 'immediately destroys the bot user if one was created', :sidekiq_inline do
        expect { subject }.not_to change { User.bots.count }
      end
    end

    shared_examples 'allows creation of bot with valid params' do
      it { expect { subject }.to change { User.count }.by(1) }

      it 'creates resource bot user' do
        response = subject

        access_token = response.payload[:access_token]

        expect(access_token.user.reload.user_type).to eq("#{resource_type}_bot")
        expect(access_token.user.created_by_id).to eq(user.id)
      end

      context 'email confirmation status' do
        shared_examples_for 'creates a user that has their email confirmed' do
          it 'creates a user that has their email confirmed' do
            response = subject
            access_token = response.payload[:access_token]

            expect(access_token.user.reload.confirmed?).to eq(true)
          end
        end

        context 'when created by an admin' do
          let(:user) { create(:admin) }

          context 'when admin mode is enabled', :enable_admin_mode do
            it_behaves_like 'creates a user that has their email confirmed'
          end

          context 'when admin mode is disabled' do
            it 'returns error' do
              response = subject

              expect(response.error?).to be true
            end
          end
        end

        context 'when created by a non-admin' do
          it_behaves_like 'creates a user that has their email confirmed'
        end
      end

      context 'bot name' do
        context 'when no name is passed' do
          it 'uses default name' do
            response = subject
            access_token = response.payload[:access_token]

            expect(access_token.user.name).to eq("#{resource.name.to_s.humanize} bot")
          end
        end

        context 'when user provides name' do
          let_it_be(:params) { { name: 'Random bot' } }

          it 'overrides the default name value' do
            response = subject
            access_token = response.payload[:access_token]

            expect(access_token.user.name).to eq(params[:name])
          end
        end
      end

      context 'access level' do
        context 'when user does not specify an access level' do
          it 'adds the bot user as a maintainer in the resource' do
            response = subject
            access_token = response.payload[:access_token]
            bot_user = access_token.user

            expect(resource.members.maintainers.map(&:user_id)).to include(bot_user.id)
          end
        end

        context 'when user specifies an access level' do
          let_it_be(:params) { { access_level: Gitlab::Access::DEVELOPER } }

          it 'adds the bot user with the specified access level in the resource' do
            response = subject
            access_token = response.payload[:access_token]
            bot_user = access_token.user

            expect(resource.members.developers.map(&:user_id)).to include(bot_user.id)
          end
        end
      end

      context 'personal access token' do
        it { expect { subject }.to change { PersonalAccessToken.count }.by(1) }

        context 'when user does not provide scope' do
          it 'has default scopes' do
            response = subject
            access_token = response.payload[:access_token]

            expect(access_token.scopes).to eq(Gitlab::Auth.resource_bot_scopes)
          end
        end

        context 'when user provides scope explicitly' do
          let_it_be(:params) { { scopes: Gitlab::Auth::REPOSITORY_SCOPES } }

          it 'overrides the default scope value' do
            response = subject
            access_token = response.payload[:access_token]

            expect(access_token.scopes).to eq(Gitlab::Auth::REPOSITORY_SCOPES)
          end
        end

        context 'expires_at' do
          context 'when no expiration value is passed' do
            it 'uses nil expiration value' do
              response = subject
              access_token = response.payload[:access_token]

              expect(access_token.expires_at).to eq(nil)
            end

            context 'expiry of the project bot member' do
              it 'project bot membership does not expire' do
                response = subject
                access_token = response.payload[:access_token]
                project_bot = access_token.user

                expect(project.members.find_by(user_id: project_bot.id).expires_at).to eq(nil)
              end
            end
          end

          context 'when user provides expiration value' do
            let_it_be(:params) { { expires_at: Date.today + 1.month } }

            it 'overrides the default expiration value' do
              response = subject
              access_token = response.payload[:access_token]

              expect(access_token.expires_at).to eq(params[:expires_at])
            end

            context 'expiry of the project bot member' do
              it 'sets the project bot to expire on the same day as the token' do
                response = subject
                access_token = response.payload[:access_token]
                project_bot = access_token.user

                expect(project.members.find_by(user_id: project_bot.id).expires_at).to eq(params[:expires_at])
              end
            end
          end

          context 'when invalid scope is passed' do
            let_it_be(:params) { { scopes: [:invalid_scope] } }

            it_behaves_like 'token creation fails'

            it 'returns the scope error message' do
              response = subject

              expect(response.error?).to be true
              expect(response.errors).to include("Scopes can only contain available scopes")
            end
          end
        end

        context "when access provisioning fails" do
          let_it_be(:bot_user) { create(:user, :project_bot) }

          let(:unpersisted_member) { build(:project_member, source: resource, user: bot_user) }

          before do
            allow_next_instance_of(ResourceAccessTokens::CreateService) do |service|
              allow(service).to receive(:create_user).and_return(bot_user)
              allow(service).to receive(:create_membership).and_return(unpersisted_member)
            end
          end

          it_behaves_like 'token creation fails'

          it 'returns the provisioning error message' do
            response = subject

            expect(response.error?).to be true
            expect(response.errors).to include("Could not provision maintainer access to project access token")
          end
        end
      end

      it 'logs the event' do
        allow(Gitlab::AppLogger).to receive(:info)

        response = subject

        expect(Gitlab::AppLogger).to have_received(:info).with(/PROJECT ACCESS TOKEN CREATION: created_by: #{user.username}, project_id: #{resource.id}, token_user: #{response.payload[:access_token].user.name}, token_id: \d+/)
      end
    end

    context 'when resource is a project' do
      let_it_be(:resource_type) { 'project' }
      let_it_be(:resource) { project }

      context 'when user does not have permission to create a resource bot' do
        it_behaves_like 'token creation fails'

        it 'returns the permission error message' do
          response = subject

          expect(response.error?).to be true
          expect(response.errors).to include("User does not have permission to create #{resource_type} access token")
        end
      end

      context 'user with valid permission' do
        before_all do
          resource.add_maintainer(user)
        end

        it_behaves_like 'allows creation of bot with valid params'
      end
    end
  end
end
