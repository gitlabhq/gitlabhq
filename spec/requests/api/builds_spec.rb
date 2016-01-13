require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:project) { create(:project, creator_id: user.id) }
  let!(:developer) { create(:project_member, user: user, project: project, access_level: ProjectMember::DEVELOPER) }
  let!(:reporter) { create(:project_member, user: user2, project: project, access_level: ProjectMember::REPORTER) }
  let(:commit) { create(:ci_commit, project: project)}
  let(:build) { create(:ci_build, commit: commit) }
  let(:build_with_trace) { create(:ci_build_with_trace, commit: commit) }
  let(:build_canceled) { create(:ci_build_canceled, commit: commit) }

  describe 'GET /projects/:id/builds ' do
    context 'authorized user' do
      it 'should return project builds' do
        get api("/projects/#{project.id}/builds", user)

        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
      end

      it 'should filter project with one scope element' do
        get api("/projects/#{project.id}/builds?scope=pending", user)

        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
      end

      it 'should filter project with array of scope elements' do
        get api("/projects/#{project.id}/builds?scope[0]=pending&scope[1]=running", user)

        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
      end

      it 'should respond 400 when scope contains invalid state' do
        get api("/projects/#{project.id}/builds?scope[0]=pending&scope[1]=unknown_status", user)

        expect(response.status).to eq(400)
      end
    end

    context 'unauthorized user' do
      it 'should not return project builds' do
        get api("/projects/#{project.id}/builds")

        expect(response.status).to eq(401)
      end
    end
  end

  describe 'GET /projects/:id/repository/commits/:sha/builds' do
    context 'authorized user' do
      it 'should return project builds for specific commit' do
        project.ensure_ci_commit(commit.sha)
        get api("/projects/#{project.id}/repository/commits/#{commit.sha}/builds", user)

        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
      end
    end

    context 'unauthorized user' do
      it 'should not return project builds' do
        project.ensure_ci_commit(commit.sha)
        get api("/projects/#{project.id}/repository/commits/#{commit.sha}/builds")

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

  describe 'POST /projects/:id/builds/:build_id/cancel' do
    context 'authorized user' do
      context 'user with :manage_builds persmission' do
        it 'should cancel running or pending build' do
          post api("/projects/#{project.id}/builds/#{build.id}/cancel", user)

          expect(response.status).to eq(201)
          expect(project.builds.first.status).to eq('canceled')
        end
      end

      context 'user without :manage_builds permission' do
        it 'should not cancel build' do
          post api("/projects/#{project.id}/builds/#{build.id}/cancel", user2)

          expect(response.status).to eq(403)
        end
      end
    end

    context 'unauthorized user' do
      it 'should not cancel build' do
        post api("/projects/#{project.id}/builds/#{build.id}/cancel")

        expect(response.status).to eq(401)
      end
    end
  end

  describe 'POST /projects/:id/builds/:build_id/retry' do
    context 'authorized user' do
      context 'user with :manage_builds persmission' do
        it 'should retry non-running build' do
          post api("/projects/#{project.id}/builds/#{build_canceled.id}/retry", user)

          expect(response.status).to eq(201)
          expect(project.builds.first.status).to eq('canceled')
          expect(json_response['status']).to eq('pending')
        end
      end

      context 'user without :manage_builds permission' do
        it 'should not retry build' do
          post api("/projects/#{project.id}/builds/#{build_canceled.id}/retry", user2)

          expect(response.status).to eq(403)
        end
      end
    end

    context 'unauthorized user' do
      it 'should not retry build' do
        post api("/projects/#{project.id}/builds/#{build_canceled.id}/retry")

        expect(response.status).to eq(401)
      end
    end
  end
end
