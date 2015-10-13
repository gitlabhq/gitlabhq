require 'spec_helper'

describe API::API, api: true do
  include ApiHelpers
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:project) { create(:project, creator_id: user.id) }
  let!(:reporter) { create(:project_member, user: user, project: project, access_level: ProjectMember::REPORTER) }
  let!(:guest) { create(:project_member, user: user2, project: project, access_level: ProjectMember::GUEST) }
  let(:commit) { project.repository.commit }
  let!(:ci_commit) { project.ensure_ci_commit(commit.id) }
  let(:commit_status) { create(:commit_status, commit: ci_commit) }

  describe "GET /projects/:id/repository/commits/:sha/statuses" do
    context "reporter user" do
      let(:statuses_id) { json_response.map { |status| status['id'] } }

      before do
        @status1 = create(:commit_status, commit: ci_commit, status: 'running')
        @status2 = create(:commit_status, commit: ci_commit, name: 'coverage', status: 'pending')
        @status3 = create(:commit_status, commit: ci_commit, name: 'coverage', ref: 'develop', status: 'running')
        @status4 = create(:commit_status, commit: ci_commit, name: 'coverage', status: 'success')
        @status5 = create(:commit_status, commit: ci_commit, ref: 'develop', status: 'success')
        @status6 = create(:commit_status, commit: ci_commit, status: 'success')
      end

      it "should return latest commit statuses" do
        get api("/projects/#{project.id}/repository/commits/#{commit.id}/statuses", user)
        expect(response.status).to eq(200)

        expect(json_response).to be_an Array
        expect(statuses_id).to contain_exactly(@status3.id, @status4.id, @status5.id, @status6.id)
      end

      it "should return all commit statuses" do
        get api("/projects/#{project.id}/repository/commits/#{commit.id}/statuses?all=1", user)
        expect(response.status).to eq(200)

        expect(json_response).to be_an Array
        expect(statuses_id).to contain_exactly(@status1.id, @status2.id, @status3.id, @status4.id, @status5.id, @status6.id)
      end

      it "should return latest commit statuses for specific ref" do
        get api("/projects/#{project.id}/repository/commits/#{commit.id}/statuses?ref=develop", user)
        expect(response.status).to eq(200)

        expect(json_response).to be_an Array
        expect(statuses_id).to contain_exactly(@status3.id, @status5.id)
      end

      it "should return latest commit statuses for specific name" do
        get api("/projects/#{project.id}/repository/commits/#{commit.id}/statuses?name=coverage", user)
        expect(response.status).to eq(200)

        expect(json_response).to be_an Array
        expect(statuses_id).to contain_exactly(@status3.id, @status4.id)
      end
    end

    context "guest user" do
      it "should not return project commits" do
        get api("/projects/#{project.id}/repository/commits/#{commit.id}/statuses", user2)
        expect(response.status).to eq(403)
      end
    end

    context "unauthorized user" do
      it "should not return project commits" do
        get api("/projects/#{project.id}/repository/commits/#{commit.id}/statuses")
        expect(response.status).to eq(401)
      end
    end
  end

  describe 'POST /projects/:id/statuses/:sha' do
    let(:post_url) { "/projects/#{project.id}/statuses/#{commit.id}" }

    context 'reporter user' do
      context 'should create commit status' do
        it 'with only required parameters' do
          post api(post_url, user), state: 'success'
          expect(response.status).to eq(201)
          expect(json_response['sha']).to eq(commit.id)
          expect(json_response['status']).to eq('success')
          expect(json_response['name']).to eq('default')
          expect(json_response['ref']).to be_nil
          expect(json_response['target_url']).to be_nil
          expect(json_response['description']).to be_nil
        end

        it 'with all optional parameters' do
          post api(post_url, user), state: 'success', context: 'coverage', ref: 'develop', target_url: 'url', description: 'test'
          expect(response.status).to eq(201)
          expect(json_response['sha']).to eq(commit.id)
          expect(json_response['status']).to eq('success')
          expect(json_response['name']).to eq('coverage')
          expect(json_response['ref']).to eq('develop')
          expect(json_response['target_url']).to eq('url')
          expect(json_response['description']).to eq('test')
        end
      end

      context 'should not create commit status' do
        it 'with invalid state' do
          post api(post_url, user), state: 'invalid'
          expect(response.status).to eq(400)
        end

        it 'without state' do
          post api(post_url, user)
          expect(response.status).to eq(400)
        end

        it 'invalid commit' do
          post api("/projects/#{project.id}/statuses/invalid_sha", user), state: 'running'
          expect(response.status).to eq(404)
        end
      end
    end

    context 'guest user' do
      it 'should not create commit status' do
        post api(post_url, user2)
        expect(response.status).to eq(403)
      end
    end

    context 'unauthorized user' do
      it 'should not create commit status' do
        post api(post_url)
        expect(response.status).to eq(401)
      end
    end
  end
end
