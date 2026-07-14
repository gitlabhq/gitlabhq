# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::ImportHistoriesController, feature_category: :importers do
  let_it_be(:owner) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, namespace: group) }

  before_all do
    group.add_developer(developer)
    group.add_owner(owner)
  end

  describe 'GET import_history' do
    let(:path) { group_import_history_path(group) }

    shared_examples 'returns 404' do
      it 'returns 404' do
        get path

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(group_import_history_visibility: false)
        sign_in(owner)
      end

      it_behaves_like 'returns 404'
    end

    context 'when feature flag is enabled' do
      before do
        stub_feature_flags(group_import_history_visibility: true)
      end

      context 'when the user is the group owner' do
        before do
          sign_in(owner)
        end

        it 'renders the show template' do
          get path

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('groups/import_histories/show')
        end
      end

      context 'when the user is admin' do
        before do
          sign_in(admin)
          allow(admin).to receive(:can_admin_all_resources?).and_return(true)
        end

        it 'renders the show template' do
          get path

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('groups/import_histories/show')
        end
      end

      context 'when the user is not the group owner' do
        before do
          sign_in(developer)
        end

        it_behaves_like 'returns 404'
      end
    end
  end
end
