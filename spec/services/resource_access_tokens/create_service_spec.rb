# frozen_string_literal: true

require 'spec_helper'

describe ResourceAccessTokens::CreateService do
  subject { described_class.new(user, resource, params).execute }

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:params) { {} }

  describe '#execute' do
    # Created shared_examples as it will easy to include specs for group bots in https://gitlab.com/gitlab-org/gitlab/-/issues/214046
    shared_examples 'fails when user does not have the permission to create a Resource Bot' do
      before_all do
        resource.add_developer(user)
      end

      it 'returns error' do
        response = subject

        expect(response.error?).to be true
        expect(response.message).to eq("User does not have permission to create #{resource_type} Access Token")
      end
    end

    shared_examples 'fails when flag is disabled' do
      before do
        stub_feature_flags(resource_access_token: false)
      end

      it 'returns nil' do
        expect(subject).to be nil
      end
    end

    shared_examples 'allows creation of bot with valid params' do
      it { expect { subject }.to change { User.count }.by(1) }

      it 'creates resource bot user' do
        response = subject

        access_token = response.payload[:access_token]

        expect(access_token.user.reload.user_type).to eq("#{resource_type}_bot")
      end

      context 'bot name' do
        context 'when no value is passed' do
          it 'uses default value' do
            response = subject
            access_token = response.payload[:access_token]

            expect(access_token.user.name).to eq("#{resource.name.to_s.humanize} bot")
          end
        end

        context 'when user provides value' do
          let_it_be(:params) { { name: 'Random bot' } }

          it 'overrides the default value' do
            response = subject
            access_token = response.payload[:access_token]

            expect(access_token.user.name).to eq(params[:name])
          end
        end
      end

      it 'adds the bot user as a maintainer in the resource' do
        response = subject
        access_token = response.payload[:access_token]
        bot_user = access_token.user

        expect(resource.members.maintainers.map(&:user_id)).to include(bot_user.id)
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

          it 'overrides the default value' do
            response = subject
            access_token = response.payload[:access_token]

            expect(access_token.scopes).to eq(Gitlab::Auth::REPOSITORY_SCOPES)
          end
        end

        context 'expires_at' do
          context 'when no value is passed' do
            it 'uses default value' do
              response = subject
              access_token = response.payload[:access_token]

              expect(access_token.expires_at).to eq(nil)
            end
          end

          context 'when user provides value' do
            let_it_be(:params) { { expires_at: Date.today + 1.month } }

            it 'overrides the default value' do
              response = subject
              access_token = response.payload[:access_token]

              expect(access_token.expires_at).to eq(params[:expires_at])
            end
          end

          context 'when invalid scope is passed' do
            let_it_be(:params) { { scopes: [:invalid_scope] } }

            it 'returns error' do
              response = subject

              expect(response.error?).to be true
            end
          end
        end
      end

      context 'when access provisioning fails' do
        before do
          allow(resource).to receive(:add_maintainer).and_return(nil)
        end

        it 'returns error' do
          response = subject

          expect(response.error?).to be true
        end
      end
    end

    context 'when resource is a project' do
      let_it_be(:resource_type) { 'project' }
      let_it_be(:resource) { project }

      it_behaves_like 'fails when user does not have the permission to create a Resource Bot'
      it_behaves_like 'fails when flag is disabled'

      context 'user with valid permission' do
        before_all do
          resource.add_maintainer(user)
        end

        it_behaves_like 'allows creation of bot with valid params'
      end
    end
  end
end
