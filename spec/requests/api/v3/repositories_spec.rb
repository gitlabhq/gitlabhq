require 'spec_helper'
require 'mime/types'

describe API::V3::Repositories do
  include RepoHelpers
  include WorkhorseHelpers

  let(:user) { create(:user) }
  let(:guest) { create(:user).tap { |u| create(:project_member, :guest, user: u, project: project) } }
  let!(:project) { create(:project, :repository, creator: user) }
  let!(:master) { create(:project_member, :master, user: user, project: project) }

  describe "GET /projects/:id/repository/tree" do
    let(:route) { "/projects/#{project.id}/repository/tree" }

    shared_examples_for 'repository tree' do
      it 'returns the repository tree' do
        get v3_api(route, current_user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array

        first_commit = json_response.first
        expect(first_commit['name']).to eq('bar')
        expect(first_commit['type']).to eq('tree')
        expect(first_commit['mode']).to eq('040000')
      end

      context 'when ref does not exist' do
        it_behaves_like '404 response' do
          let(:request) { get v3_api("#{route}?ref_name=foo", current_user) }
          let(:message) { '404 Tree Not Found' }
        end
      end

      context 'when repository is disabled' do
        include_context 'disabled repository'

        it_behaves_like '403 response' do
          let(:request) { get v3_api(route, current_user) }
        end
      end

      context 'with recursive=1' do
        it 'returns recursive project paths tree' do
          get v3_api("#{route}?recursive=1", current_user)

          expect(response.status).to eq(200)
          expect(json_response).to be_an Array
          expect(json_response[4]['name']).to eq('html')
          expect(json_response[4]['path']).to eq('files/html')
          expect(json_response[4]['type']).to eq('tree')
          expect(json_response[4]['mode']).to eq('040000')
        end

        context 'when repository is disabled' do
          include_context 'disabled repository'

          it_behaves_like '403 response' do
            let(:request) { get v3_api(route, current_user) }
          end
        end

        context 'when ref does not exist' do
          it_behaves_like '404 response' do
            let(:request) { get v3_api("#{route}?recursive=1&ref_name=foo", current_user) }
            let(:message) { '404 Tree Not Found' }
          end
        end
      end
    end

    context 'when unauthenticated', 'and project is public' do
      it_behaves_like 'repository tree' do
        let(:project) { create(:project, :public, :repository) }
        let(:current_user) { nil }
      end
    end

    context 'when unauthenticated', 'and project is private' do
      it_behaves_like '404 response' do
        let(:request) { get v3_api(route) }
        let(:message) { '404 Project Not Found' }
      end
    end

    context 'when authenticated', 'as a developer' do
      it_behaves_like 'repository tree' do
        let(:current_user) { user }
      end
    end

    context 'when authenticated', 'as a guest' do
      it_behaves_like '403 response' do
        let(:request) { get v3_api(route, guest) }
      end
    end
  end

  [
    ['blobs/:sha', 'blobs/master'],
    ['blobs/:sha', 'blobs/v1.1.0'],
    ['commits/:sha/blob', 'commits/master/blob']
  ].each do |desc_path, example_path|
    describe "GET /projects/:id/repository/#{desc_path}" do
      let(:route) { "/projects/#{project.id}/repository/#{example_path}?filepath=README.md" }
      shared_examples_for 'repository blob' do
        it 'returns the repository blob' do
          get v3_api(route, current_user)
          expect(response).to have_gitlab_http_status(200)
        end
        context 'when sha does not exist' do
          it_behaves_like '404 response' do
            let(:request) { get v3_api("/projects/#{project.id}/repository/#{desc_path.sub(':sha', 'invalid_branch_name')}?filepath=README.md", current_user) }
            let(:message) { '404 Commit Not Found' }
          end
        end
        context 'when filepath does not exist' do
          it_behaves_like '404 response' do
            let(:request) { get v3_api(route.sub('README.md', 'README.invalid'), current_user) }
            let(:message) { '404 File Not Found' }
          end
        end
        context 'when no filepath is given' do
          it_behaves_like '400 response' do
            let(:request) { get v3_api(route.sub('?filepath=README.md', ''), current_user) }
          end
        end
        context 'when repository is disabled' do
          include_context 'disabled repository'
          it_behaves_like '403 response' do
            let(:request) { get v3_api(route, current_user) }
          end
        end
      end
      context 'when unauthenticated', 'and project is public' do
        it_behaves_like 'repository blob' do
          let(:project) { create(:project, :public, :repository) }
          let(:current_user) { nil }
        end
      end
      context 'when unauthenticated', 'and project is private' do
        it_behaves_like '404 response' do
          let(:request) { get v3_api(route) }
          let(:message) { '404 Project Not Found' }
        end
      end
      context 'when authenticated', 'as a developer' do
        it_behaves_like 'repository blob' do
          let(:current_user) { user }
        end
      end
      context 'when authenticated', 'as a guest' do
        it_behaves_like '403 response' do
          let(:request) { get v3_api(route, guest) }
        end
      end
    end
  end
  describe "GET /projects/:id/repository/raw_blobs/:sha" do
    let(:route) { "/projects/#{project.id}/repository/raw_blobs/#{sample_blob.oid}" }
    shared_examples_for 'repository raw blob' do
      it 'returns the repository raw blob' do
        get v3_api(route, current_user)
        expect(response).to have_gitlab_http_status(200)
      end
      context 'when sha does not exist' do
        it_behaves_like '404 response' do
          let(:request) { get v3_api(route.sub(sample_blob.oid, '123456'), current_user) }
          let(:message) { '404 Blob Not Found' }
        end
      end
      context 'when repository is disabled' do
        include_context 'disabled repository'
        it_behaves_like '403 response' do
          let(:request) { get v3_api(route, current_user) }
        end
      end
    end
    context 'when unauthenticated', 'and project is public' do
      it_behaves_like 'repository raw blob' do
        let(:project) { create(:project, :public, :repository) }
        let(:current_user) { nil }
      end
    end
    context 'when unauthenticated', 'and project is private' do
      it_behaves_like '404 response' do
        let(:request) { get v3_api(route) }
        let(:message) { '404 Project Not Found' }
      end
    end
    context 'when authenticated', 'as a developer' do
      it_behaves_like 'repository raw blob' do
        let(:current_user) { user }
      end
    end
    context 'when authenticated', 'as a guest' do
      it_behaves_like '403 response' do
        let(:request) { get v3_api(route, guest) }
      end
    end
  end
  describe "GET /projects/:id/repository/archive(.:format)?:sha" do
    let(:route) { "/projects/#{project.id}/repository/archive" }
    shared_examples_for 'repository archive' do
      it 'returns the repository archive' do
        get v3_api(route, current_user)
        expect(response).to have_gitlab_http_status(200)
        repo_name = project.repository.name.gsub("\.git", "")
        type, params = workhorse_send_data
        expect(type).to eq('git-archive')
        expect(params['ArchivePath']).to match(/#{repo_name}\-[^\.]+\.tar.gz/)
      end
      it 'returns the repository archive archive.zip' do
        get v3_api("/projects/#{project.id}/repository/archive.zip", user)
        expect(response).to have_gitlab_http_status(200)
        repo_name = project.repository.name.gsub("\.git", "")
        type, params = workhorse_send_data
        expect(type).to eq('git-archive')
        expect(params['ArchivePath']).to match(/#{repo_name}\-[^\.]+\.zip/)
      end
      it 'returns the repository archive archive.tar.bz2' do
        get v3_api("/projects/#{project.id}/repository/archive.tar.bz2", user)
        expect(response).to have_gitlab_http_status(200)
        repo_name = project.repository.name.gsub("\.git", "")
        type, params = workhorse_send_data
        expect(type).to eq('git-archive')
        expect(params['ArchivePath']).to match(/#{repo_name}\-[^\.]+\.tar.bz2/)
      end
      context 'when sha does not exist' do
        it_behaves_like '404 response' do
          let(:request) { get v3_api("#{route}?sha=xxx", current_user) }
          let(:message) { '404 File Not Found' }
        end
      end
    end
    context 'when unauthenticated', 'and project is public' do
      it_behaves_like 'repository archive' do
        let(:project) { create(:project, :public, :repository) }
        let(:current_user) { nil }
      end
    end
    context 'when unauthenticated', 'and project is private' do
      it_behaves_like '404 response' do
        let(:request) { get v3_api(route) }
        let(:message) { '404 Project Not Found' }
      end
    end
    context 'when authenticated', 'as a developer' do
      it_behaves_like 'repository archive' do
        let(:current_user) { user }
      end
    end
    context 'when authenticated', 'as a guest' do
      it_behaves_like '403 response' do
        let(:request) { get v3_api(route, guest) }
      end
    end
  end

  describe 'GET /projects/:id/repository/compare' do
    let(:route) { "/projects/#{project.id}/repository/compare" }
    shared_examples_for 'repository compare' do
      it "compares branches" do
        get v3_api(route, current_user), from: 'master', to: 'feature'
        expect(response).to have_gitlab_http_status(200)
        expect(json_response['commits']).to be_present
        expect(json_response['diffs']).to be_present
      end
      it "compares tags" do
        get v3_api(route, current_user), from: 'v1.0.0', to: 'v1.1.0'
        expect(response).to have_gitlab_http_status(200)
        expect(json_response['commits']).to be_present
        expect(json_response['diffs']).to be_present
      end
      it "compares commits" do
        get v3_api(route, current_user), from: sample_commit.id, to: sample_commit.parent_id
        expect(response).to have_gitlab_http_status(200)
        expect(json_response['commits']).to be_empty
        expect(json_response['diffs']).to be_empty
        expect(json_response['compare_same_ref']).to be_falsey
      end
      it "compares commits in reverse order" do
        get v3_api(route, current_user), from: sample_commit.parent_id, to: sample_commit.id
        expect(response).to have_gitlab_http_status(200)
        expect(json_response['commits']).to be_present
        expect(json_response['diffs']).to be_present
      end
      it "compares same refs" do
        get v3_api(route, current_user), from: 'master', to: 'master'
        expect(response).to have_gitlab_http_status(200)
        expect(json_response['commits']).to be_empty
        expect(json_response['diffs']).to be_empty
        expect(json_response['compare_same_ref']).to be_truthy
      end
    end
    context 'when unauthenticated', 'and project is public' do
      it_behaves_like 'repository compare' do
        let(:project) { create(:project, :public, :repository) }
        let(:current_user) { nil }
      end
    end
    context 'when unauthenticated', 'and project is private' do
      it_behaves_like '404 response' do
        let(:request) { get v3_api(route) }
        let(:message) { '404 Project Not Found' }
      end
    end
    context 'when authenticated', 'as a developer' do
      it_behaves_like 'repository compare' do
        let(:current_user) { user }
      end
    end
    context 'when authenticated', 'as a guest' do
      it_behaves_like '403 response' do
        let(:request) { get v3_api(route, guest) }
      end
    end
  end

  describe 'GET /projects/:id/repository/contributors' do
    let(:route) { "/projects/#{project.id}/repository/contributors" }

    shared_examples_for 'repository contributors' do
      it 'returns valid data' do
        get v3_api(route, current_user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array

        first_contributor = json_response.first
        expect(first_contributor['email']).to eq('tiagonbotelho@hotmail.com')
        expect(first_contributor['name']).to eq('tiagonbotelho')
        expect(first_contributor['commits']).to eq(1)
        expect(first_contributor['additions']).to eq(0)
        expect(first_contributor['deletions']).to eq(0)
      end
    end

    context 'when unauthenticated', 'and project is public' do
      it_behaves_like 'repository contributors' do
        let(:project) { create(:project, :public, :repository) }
        let(:current_user) { nil }
      end
    end

    context 'when unauthenticated', 'and project is private' do
      it_behaves_like '404 response' do
        let(:request) { get v3_api(route) }
        let(:message) { '404 Project Not Found' }
      end
    end

    context 'when authenticated', 'as a developer' do
      it_behaves_like 'repository contributors' do
        let(:current_user) { user }
      end
    end

    context 'when authenticated', 'as a guest' do
      it_behaves_like '403 response' do
        let(:request) { get v3_api(route, guest) }
      end
    end
  end
end
