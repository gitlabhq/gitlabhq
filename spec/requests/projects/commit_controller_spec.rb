# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::CommitController, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.owner }

  describe 'GET #diff_files' do
    let(:master_pickable_sha) { '7d3b0f7cff5f37573aea97cebfd5692ea1689924' }
    let(:format) { :html }
    let(:params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: master_pickable_sha,
        format: format
      }
    end

    before_all do
      project.add_maintainer(user)
    end

    context 'without expanded parameter' do
      before do
        sign_in(user)
      end

      it 'does not rate limit the endpoint' do
        get diff_files_namespace_project_commit_url(params)

        expect(::Gitlab::ApplicationRateLimiter)
          .not_to receive(:throttled?).with(:expanded_diff_files, scope: user)
      end
    end

    context 'with expanded parameter' do
      before do
        params[:expanded] = 1
      end

      context 'with signed in user' do
        it_behaves_like 'rate limited endpoint', rate_limit_key: :expanded_diff_files do
          let_it_be(:current_user) { user }

          before do
            sign_in current_user
          end

          def request
            get diff_files_namespace_project_commit_url(params), params: { scope: user }
          end
        end
      end

      context 'without a signed in user' do
        it_behaves_like 'rate limited endpoint', rate_limit_key: :expanded_diff_files do
          let_it_be(:project) { create(:project, :public, :repository) }
          let(:request_ip) { '1.2.3.4' }

          def request
            get diff_files_namespace_project_commit_url(params),
              params: { scope: request_ip }, env: { REMOTE_ADDR: request_ip }
          end
        end
      end
    end
  end
end
