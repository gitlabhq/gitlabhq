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

  describe '#index' do
    let_it_be(:project) { create(:project, :repository, :public) }
    let_it_be(:user) { create(:user) }

    before do
      sign_in(user)
    end

    context 'when tag has a signature but lazy_cached_signature resolves to nil' do
      it 'does not raise an error' do
        tag = project.repository.find_tag('v1.0.0')
        allow(tag).to receive_messages(
          has_signature?: true,
          can_use_lazy_cached_signature?: true,
          lazy_cached_signature: nil
        )

        allow_next_instance_of(TagsFinder) do |finder|
          allow(finder).to receive(:execute).and_return([tag])
        end

        get project_tags_path(project)

        expect(response).to have_gitlab_http_status(:ok)
      end
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

    context 'when tag has a signature but lazy_cached_signature resolves to nil' do
      let(:tag_name) { 'v1.0.0' }

      before do
        tag = project.repository.find_tag(tag_name)
        allow(tag).to receive_messages(
          has_signature?: true,
          can_use_lazy_cached_signature?: true,
          lazy_cached_signature: nil
        )
        allow(project.repository).to receive(:find_tag).and_call_original
        allow(project.repository).to receive(:find_tag).with(tag_name).and_return(tag)
      end

      it 'does not raise an error' do
        get project_tag_path(project, id: tag_name)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
