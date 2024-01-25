# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::TagsController, feature_category: :source_code_management do
  context 'token authentication' do
    context 'when public project' do
      let_it_be(:public_project) { create(:project, :repository, :public) }

      it_behaves_like 'authenticates sessionless user for the request spec', 'index atom', public_resource: true do
        let(:url) { project_tags_url(public_project, format: :atom) }
      end
    end

    context 'when private project' do
      let_it_be(:private_project) { create(:project, :repository, :private) }

      it_behaves_like 'authenticates sessionless user for the request spec', 'index atom', public_resource: false, ignore_metrics: true do
        let(:url) { project_tags_url(private_project, format: :atom) }

        before do
          private_project.add_maintainer(user)
        end
      end
    end
  end

  describe "atom feed contents" do
    let_it_be(:project) { create(:project, :repository, :public) }

    it "returns the author's public email address rather than the commit email, when present" do
      get(project_tags_url(project, format: :atom))

      doc = Hash.from_xml(response.body)
      commit_entry = doc["feed"]["entry"].first

      expect(commit_entry["author"]).to be_a(Hash)
      expect(commit_entry["author"]["name"]).to be_a(String)
      expect(commit_entry["author"]["email"]).to be_a(String)
    end
  end

  describe '#show' do
    let_it_be(:project) { create(:project, :repository, :public) }
    let_it_be(:user) { create(:user) }

    before do
      sign_in(user)
    end

    context 'with x509 signature' do
      let(:tag_name) { 'v1.1.1' }

      it 'displays a signature badge' do
        get project_tags_path(project, id: tag_name)

        expect(response.body).to include('Unverified')
      end
    end
  end
end
