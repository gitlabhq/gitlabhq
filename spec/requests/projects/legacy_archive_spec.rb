# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Legacy repository archive endpoint', feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :private, :repository) }
  let_it_be(:user) { create(:user) }

  let(:archive_project) { project }
  let(:format) { 'tar.gz' }

  subject(:send_request) { get "/#{archive_project.full_path}/repository/archive.#{format}", params: { ref: 'master' } }

  describe 'GET /:namespace/:project/repository/archive.tar.gz' do
    context 'when user is unauthenticated' do
      before do
        send_request
      end

      it 'returns 404 and does not redirect to sign-in page' do
        expect(response).to have_gitlab_http_status(:not_found)
        expect(response).not_to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated' do
      before do
        sign_in(user)
        send_request
      end

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is a project member' do
      before_all do
        project.add_developer(user)
      end

      before do
        sign_in(user)
        send_request
      end

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with different archive formats' do
      using RSpec::Parameterized::TableSyntax

      where(:format) do
        %w[zip tar tar.gz tgz gz tar.bz2 tbz tbz2 tb2 bz2]
      end

      with_them do
        it 'returns 404' do
          send_request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with a public project' do
      let_it_be(:public_project) { create(:project, :public, :repository) }

      let(:archive_project) { public_project }

      before do
        send_request
      end

      it 'returns 404 for unauthenticated requests' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with nested namespace' do
      let_it_be(:group) { create(:group) }
      let_it_be(:subgroup) { create(:group, parent: group) }
      let_it_be(:nested_project) { create(:project, :private, :repository, namespace: subgroup) }

      let(:archive_project) { nested_project }

      before do
        send_request
      end

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when legacy_archive_not_found feature flag is disabled' do
      before do
        stub_feature_flags(legacy_archive_not_found: false)
      end

      context 'when user is unauthenticated' do
        before do
          send_request
        end

        it 'redirects to sign-in page (legacy catch-all behavior)' do
          expect(response).to have_gitlab_http_status(:redirect)
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'when user is authenticated' do
        before do
          sign_in(user)
          send_request
        end

        it 'returns 404' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when request is from a search engine bot' do
        before do
          get "/#{archive_project.full_path}/repository/archive.#{format}",
            params: { ref: 'master' },
            headers: { 'User-Agent' => 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)' }
        end

        it 'returns 404 and does not redirect to sign-in page' do
          expect(response).to have_gitlab_http_status(:not_found)
          expect(response).not_to redirect_to(new_user_session_path)
        end
      end
    end
  end
end
