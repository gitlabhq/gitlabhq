# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Projects::RedirectController requests", feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:private_project) { create(:project, :private) }
  let_it_be(:private_project2) { create(:project, :private) }
  let_it_be(:public_project) { create(:project, :public) }
  let_it_be(:user) { create(:user, developer_of: private_project) }

  shared_examples 'project redirect' do |endpoint_format|
    where(:authenticated, :project, :is_found) do
      true  | ref(:private_project)        | true
      false | ref(:private_project)        | false
      true  | ref(:private_project2)       | false
      true  | ref(:public_project)         | true
      false | ref(:public_project)         | true
      true  | build(:project, id: 0)       | false
    end

    with_them do
      before do
        sign_in(user) if authenticated

        get format(endpoint_format, id: project.id)
      end

      if params[:is_found]
        it 'redirects to the project page' do
          expect(response).to have_gitlab_http_status(:found)
          expect(response).to redirect_to(project_path(project))
        end
      else
        it 'gives 404' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'GET redirect_from_id' do
    it_behaves_like 'project redirect', '/projects/%{id}'
    it_behaves_like 'project redirect', '/-/p/%{id}'
  end

  # This is a regression test for https://gitlab.com/gitlab-org/gitlab/-/issues/351058
  context 'with sourcegraph enabled' do
    let_it_be(:sourcegraph_url) { 'https://sourcegraph.test' }

    before do
      allow(Gitlab::CurrentSettings).to receive(:sourcegraph_url).and_return(sourcegraph_url)
      allow(Gitlab::CurrentSettings).to receive(:sourcegraph_enabled).and_return(true)

      sign_in(user)
    end

    context 'with projects/:id route' do
      subject { get "/projects/#{public_project.id}" }

      it 'redirects successfully' do
        subject

        expect(response).to redirect_to(project_path(public_project))
      end
    end
  end
end
