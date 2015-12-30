require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:project) { create(:project, creator_id: user.id) }
  let!(:master) { create(:project_member, user: user, project: project, access_level: ProjectMember::MASTER) }
  let!(:guest) { create(:project_member, user: user2, project: project, access_level: ProjectMember::GUEST) }
  let(:commit) { create(:ci_commit, project: project)}
  let(:build) { create(:ci_build, commit: commit) }
  let(:build_with_trace) { create(:ci_build_with_trace, commit: commit) }

  describe 'GET /projects/:id/builds ' do
    context 'authorized user' do
      it 'should return project builds' do
        get api("/projects/#{project.id}/builds", user)

        puts json_response
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
      end
    end

    context 'unauthorized user' do
      it 'should not return project builds' do
        get api("/projects/#{project.id}/builds")

        expect(response.status).to eq(401)
      end
    end
  end

  describe 'GET /projects/:id/builds/commit/:sha' do
    context 'authorized user' do
      it 'should return project builds for specific commit' do
        project.ensure_ci_commit(commit.sha)
        get api("/projects/#{project.id}/builds/commit/#{project.ci_commits.first.sha}", user)

        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
      end
    end

    context 'unauthorized user' do
      it 'should not return project builds' do
        project.ensure_ci_commit(commit.sha)
        get api("/projects/#{project.id}/builds/commit/#{project.ci_commits.first.sha}")

        expect(response.status).to eq(401)
      end
    end
  end

  describe 'GET /projects/:id/builds/:build_id(/trace)?' do
    context 'authorized user' do
      it 'should return specific build data' do
        get api("/projects/#{project.id}/builds/#{build.id}", user)

        expect(response.status).to eq(200)
        expect(json_response['name']).to eq('test')
        expect(json_response['commit']['sha']).to eq(commit.sha)
      end

      it 'should return specific build trace' do
        get api("/projects/#{project.id}/builds/#{build_with_trace.id}/trace", user)

        expect(response.status).to eq(200)
        expect(response.body).to eq(build_with_trace.trace)
      end
    end

    context 'unauthorized user' do
      it 'should not return specific build data' do
        get api("/projects/#{project.id}/builds/#{build.id}")

        expect(response.status).to eq(401)
      end

      it 'should not return specific build trace' do
        get api("/projects/#{project.id}/builds/#{build_with_trace.id}/trace")

        expect(response.status).to eq(401)
      end
    end
  end
end
