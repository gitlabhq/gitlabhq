# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Crm::OrganizationsController do
  let_it_be(:user) { create(:user) }

  shared_examples 'response with 404 status' do
    it 'returns 404' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'ok response with index template' do
    it 'renders the index template' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:index)
    end
  end

  shared_examples 'ok response with index template if authorized' do
    context 'private group' do
      let(:group) { create(:group, :private) }

      context 'with authorized user' do
        before do
          group.add_reporter(user)
          sign_in(user)
        end

        context 'when feature flag is enabled' do
          it_behaves_like 'ok response with index template'
        end

        context 'when feature flag is not enabled' do
          before do
            stub_feature_flags(customer_relations: false)
          end

          it_behaves_like 'response with 404 status'
        end
      end

      context 'with unauthorized user' do
        before do
          sign_in(user)
        end

        it_behaves_like 'response with 404 status'
      end

      context 'with anonymous user' do
        it 'blah' do
          subject

          expect(response).to have_gitlab_http_status(:found)
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context 'public group' do
      let(:group) { create(:group, :public) }

      context 'with anonymous user' do
        it_behaves_like 'ok response with index template'
      end
    end
  end

  describe 'GET #index' do
    subject do
      get group_crm_organizations_path(group)
      response
    end

    it_behaves_like 'ok response with index template if authorized'
  end

  describe 'GET #new' do
    subject do
      get new_group_crm_organization_path(group)
    end

    it_behaves_like 'ok response with index template if authorized'
  end
end
