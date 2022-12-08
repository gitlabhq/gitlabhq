# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::CommitsController, feature_category: :source_code_management do
  context 'token authentication' do
    context 'when public project' do
      let_it_be(:public_project) { create(:project, :repository, :public) }

      it_behaves_like 'authenticates sessionless user for the request spec', 'show atom', public_resource: true do
        let(:url) { project_commits_url(public_project, public_project.default_branch, format: :atom) }
      end
    end

    context 'when private project' do
      let_it_be(:private_project) { create(:project, :repository, :private) }

      it_behaves_like 'authenticates sessionless user for the request spec', 'show atom', public_resource: false, ignore_metrics: true do
        let(:url) { project_commits_url(private_project, private_project.default_branch, format: :atom) }

        before do
          private_project.add_maintainer(user)
        end
      end
    end
  end
end
