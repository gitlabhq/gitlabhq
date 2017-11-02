require 'spec_helper'
require 'mime/types'

describe API::V3::Tags do
  include RepoHelpers

  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:project) { create(:project, :repository, creator: user) }
  let!(:master) { create(:project_member, :master, user: user, project: project) }

  describe "GET /projects/:id/repository/tags" do
    let(:tag_name) { project.repository.tag_names.sort.reverse.first }
    let(:description) { 'Awesome release!' }

    shared_examples_for 'repository tags' do
      it 'returns the repository tags' do
        get v3_api("/projects/#{project.id}/repository/tags", current_user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.first['name']).to eq(tag_name)
      end
    end

    context 'when unauthenticated' do
      it_behaves_like 'repository tags' do
        let(:project) { create(:project, :public, :repository) }
        let(:current_user) { nil }
      end
    end

    context 'when authenticated' do
      it_behaves_like 'repository tags' do
        let(:current_user) { user }
      end
    end

    context 'without releases' do
      it "returns an array of project tags" do
        get v3_api("/projects/#{project.id}/repository/tags", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.first['name']).to eq(tag_name)
      end
    end

    context 'with releases' do
      before do
        release = project.releases.find_or_initialize_by(tag: tag_name)
        release.update_attributes(description: description)
      end

      it "returns an array of project tags with release info" do
        get v3_api("/projects/#{project.id}/repository/tags", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.first['name']).to eq(tag_name)
        expect(json_response.first['message']).to eq('Version 1.1.0')
        expect(json_response.first['release']['description']).to eq(description)
      end
    end
  end

  describe 'DELETE /projects/:id/repository/tags/:tag_name' do
    let(:tag_name) { project.repository.tag_names.sort.reverse.first }

    before do
      allow_any_instance_of(Repository).to receive(:rm_tag).and_return(true)
    end

    context 'delete tag' do
      it 'deletes an existing tag' do
        delete v3_api("/projects/#{project.id}/repository/tags/#{tag_name}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['tag_name']).to eq(tag_name)
      end

      it 'raises 404 if the tag does not exist' do
        delete v3_api("/projects/#{project.id}/repository/tags/foobar", user)
        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
