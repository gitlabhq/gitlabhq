# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Projects::Integrations::SlashCommandsController, feature_category: :integrations do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, developer_of: project) }
  let_it_be(:chat_name) { create(:chat_name, user: user) }

  let(:params) do
    {
      command_id: 'command-id',
      integration: 'mattermost_slash_commands',
      team: 1,
      channel: 2,
      response_url: 'http://www.example.com'
    }
  end

  before do
    create(:mattermost_slash_commands_integration, project: project)
  end

  describe 'GET #show' do
    context 'when user is signed in' do
      before do
        sign_in(user)
      end

      context 'when request is invalid' do
        it 'renders the "show" template with expired message' do
          get project_integrations_slash_commands_path(project), params: params

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:show)
          expect(response.body).to include(
            'The slash command verification request has expired. Please run the command again.'
          )
        end
      end

      context 'when request is valid', :use_clean_rails_memory_store_caching do
        before do
          Rails.cache.write(
            "slash-command-requests:#{params[:command_id]}", { team_id: chat_name.team_id, user_id: chat_name.chat_id }
          )
          stub_request(:post, "http://www.example.com/").to_return(status: 200, body: 'ok')
        end

        context 'when user is valid' do
          it 'renders the "show" template with authorize button' do
            get project_integrations_slash_commands_path(project), params: params

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template(:show)
            expect(response.body).to include('Authorize')
          end
        end

        context 'when user is invalid' do
          let(:chat_name) { create(:chat_name) }

          it 'renders the "show" template' do
            get project_integrations_slash_commands_path(project), params: params

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template(:show)
            expect(response.body).to include('The slash command request is invalid.')
          end
        end
      end
    end

    context 'when user is not signed in' do
      it 'redirects with a status of 302' do
        get project_integrations_slash_commands_path(project), params: params

        expect(response).to have_gitlab_http_status(:redirect)
      end
    end
  end

  describe 'POST #confirm' do
    let(:params) { super().merge(redirect_url: 'http://www.example.com') }

    context 'when user is signed in' do
      before do
        sign_in(user)
      end

      context 'when request is invalid' do
        it 'renders the "show" template' do
          post confirm_project_integrations_slash_commands_path(project), params: params

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:show)
          expect(response.body).to include('The slash command request is invalid.')
        end
      end

      context 'when request is valid', :use_clean_rails_memory_store_caching do
        before do
          Rails.cache.write(
            "slash-command-requests:#{params[:command_id]}", { team_id: chat_name.team_id, user_id: chat_name.chat_id }
          )
          stub_request(:post, "http://www.example.com/").to_return(status: 200, body: 'ok')
        end

        context 'when user is valid' do
          it 'redirects back to the integration' do
            post confirm_project_integrations_slash_commands_path(project), params: params

            expect(response).to have_gitlab_http_status(:redirect)
          end
        end

        context 'when user is invalid' do
          let(:chat_name) { create(:chat_name) }

          it 'renders the "show" template' do
            post confirm_project_integrations_slash_commands_path(project), params: params

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template(:show)
            expect(response.body).to include('The slash command request is invalid.')
          end
        end
      end
    end

    context 'when user is not signed in' do
      it 'redirects with a status of 302' do
        post confirm_project_integrations_slash_commands_path(project), params: params

        expect(response).to have_gitlab_http_status(:redirect)
      end
    end
  end
end
