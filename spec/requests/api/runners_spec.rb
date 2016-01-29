require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers

  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:project) { create(:project, creator_id: user.id) }
  let!(:project2) { create(:project, creator_id: user.id) }
  let!(:master) { create(:project_member, user: user, project: project, access_level: ProjectMember::MASTER) }
  let!(:master2) { create(:project_member, user: user, project: project2, access_level: ProjectMember::MASTER) }
  let!(:developer) { create(:project_member, user: user2, project: project, access_level: ProjectMember::REPORTER) }
  let!(:shared_runner) { create(:ci_shared_runner, tag_list: ['mysql', 'ruby'], active: true) }
  let!(:specific_runner) { create(:ci_specific_runner, tag_list: ['mysql', 'ruby']) }
  let!(:specific_runner_project) { create(:ci_runner_project, runner: specific_runner, project: project) }
  let!(:specific_runner2) { create(:ci_specific_runner) }
  let!(:specific_runner2_project) { create(:ci_runner_project, runner: specific_runner2, project: project2) }
  let!(:unused_specific_runner) { create(:ci_specific_runner) }
  let!(:two_projects_runner) { create(:ci_specific_runner) }
  let!(:two_projects_runner_project) { create(:ci_runner_project, runner: two_projects_runner, project: project) }
  let!(:two_projects_runner_project2) { create(:ci_runner_project, runner: two_projects_runner, project: project2) }

  describe 'GET /runners' do
    context 'authorized user' do
      context 'authorized user with admin privileges' do
        it 'should return all runners' do
          get api('/runners', admin)
          shared = false || json_response.map{ |r| r['is_shared'] }.inject{ |sum, shr| sum || shr}

          expect(response.status).to eq(200)
          expect(json_response).to be_an Array
          expect(shared).to be_truthy
        end
      end

      context 'authorized user without admin privileges' do
        it 'should return user available runners' do
          get api('/runners', user)
          shared = false || json_response.map{ |r| r['is_shared'] }.inject{ |sum, shr| sum || shr}

          expect(response.status).to eq(200)
          expect(json_response).to be_an Array
          expect(shared).to be_falsey
        end
      end

      it 'should filter runners by scope' do
        get api('/runners?scope=specific', user)
        shared = false || json_response.map{ |r| r['is_shared'] }.inject{ |sum, shr| sum || shr}

        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(shared).to be_falsey
      end

      it 'should avoid filtering if scope is invalid' do
        get api('/runners?scope=unknown', user)
        expect(response.status).to eq(400)
      end
    end

    context 'unauthorized user' do
      it 'should not return runners' do
        get api('/runners')

        expect(response.status).to eq(401)
      end
    end
  end

  describe 'GET /runners/:id' do
    context 'admin user' do
      it "should return runner's details" do
        get api("/runners/#{specific_runner.id}", admin)

        expect(response.status).to eq(200)
        expect(json_response['description']).to eq(specific_runner.description)
      end

      it "should return shared runner's details" do
        get api("/runners/#{shared_runner.id}", admin)

        expect(response.status).to eq(200)
        expect(json_response['description']).to eq(shared_runner.description)
      end

      it 'should return 404 if runner does not exists' do
        get api('/runners/9999', admin)

        expect(response.status).to eq(404)
      end
    end

    context "runner project's administrative user" do
      it "should return runner's details" do
        get api("/runners/#{specific_runner.id}", user)

        expect(response.status).to eq(200)
        expect(json_response['description']).to eq(specific_runner.description)
      end

      it "should return shared runner's details" do
        get api("/runners/#{shared_runner.id}", user)

        expect(response.status).to eq(200)
        expect(json_response['description']).to eq(shared_runner.description)
      end
    end

    context 'other authorized user' do
      it "should not return runner's details" do
        get api("/runners/#{specific_runner.id}", user2)

        expect(response.status).to eq(403)
      end
    end

    context 'unauthorized user' do
      it "should not return runner's details" do
        get api("/runners/#{specific_runner.id}")

        expect(response.status).to eq(401)
      end
    end
  end

  describe 'PUT /runners/:id' do
    context 'admin user' do
      it 'should update shared runner' do
        description = shared_runner.description
        active = shared_runner.active
        tag_list = shared_runner.tag_list
        put api("/runners/#{shared_runner.id}", admin), description: "#{description}_updated", active: !active,
                                                        tag_list: ['ruby2.1', 'pgsql', 'mysql']
        shared_runner.reload

        expect(response.status).to eq(200)
        expect(shared_runner.description).not_to eq(description)
        expect(shared_runner.active).not_to eq(active)
        expect(shared_runner.tag_list).not_to eq(tag_list)
      end

      it 'should update specific runner' do
        description = specific_runner.description
        put api("/runners/#{specific_runner.id}", admin), description: 'test'
        specific_runner.reload

        expect(response.status).to eq(200)
        expect(specific_runner.description).to eq('test')
        expect(specific_runner.description).not_to eq(description)
      end

      it 'should return 404 if runner does not exists' do
        put api('/runners/9999', admin), description: 'test'

        expect(response.status).to eq(404)
      end
    end

    context 'authorized user' do
      it 'should not update shared runner' do
        put api("/runners/#{shared_runner.id}", user), description: 'test'

        expect(response.status).to eq(403)
      end

      it 'should not update specific runner without access to' do
        put api("/runners/#{specific_runner.id}", user2), description: 'test'

        expect(response.status).to eq(403)
      end

      it 'should update specific runner' do
        description = specific_runner.description
        put api("/runners/#{specific_runner.id}", admin), description: 'test'
        specific_runner.reload

        expect(response.status).to eq(200)
        expect(specific_runner.description).to eq('test')
        expect(specific_runner.description).not_to eq(description)
      end

    end

    context 'unauthorized user' do
      it 'should not delete runner' do
        put api("/runners/#{specific_runner.id}"), description: 'test'

        expect(response.status).to eq(401)
      end
    end
  end

  describe 'DELETE /runners/:id' do
    context 'admin user' do
      it 'should delete shared runner' do
        expect do
          delete api("/runners/#{shared_runner.id}", admin)
        end.to change{ Ci::Runner.shared.count }.by(-1)
        expect(response.status).to eq(200)
      end

      it 'should delete unused specific runner' do
        expect do
          delete api("/runners/#{unused_specific_runner.id}", admin)
        end.to change{ Ci::Runner.specific.count }.by(-1)
        expect(response.status).to eq(200)
      end

      it 'should delete used specific runner' do
        expect do
          delete api("/runners/#{specific_runner.id}", admin)
        end.to change{ Ci::Runner.specific.count }.by(-1)
        expect(response.status).to eq(200)
      end

      it 'should return 404 if runner does not exists' do
        delete api('/runners/9999', admin)

        expect(response.status).to eq(404)
      end
    end

    context 'authorized user' do
      it 'should not delete shared runner' do
        delete api("/runners/#{shared_runner.id}", user)
        expect(response.status).to eq(403)
      end

      it 'should not delete runner without access to' do
        delete api("/runners/#{specific_runner.id}", user2)
        expect(response.status).to eq(403)
      end

      it 'should not delete runner with more than one associated project' do
        delete api("/runners/#{two_projects_runner.id}", user)
        expect(response.status).to eq(403)
      end

      it 'should delete runner for one owned project' do
        expect do
          delete api("/runners/#{specific_runner.id}", user)
        end.to change{ Ci::Runner.specific.count }.by(-1)
        expect(response.status).to eq(200)
      end
    end

    context 'unauthorized user' do
      it 'should not delete runner' do
        delete api("/runners/#{specific_runner.id}")

        expect(response.status).to eq(401)
      end
    end
  end

  describe 'GET /projects/:id/runners' do
    context 'authorized user with master privileges' do
      it "should return project's runners" do
        get api("/projects/#{project.id}/runners", user)
        shared = false || json_response.map{ |r| r['is_shared'] }.inject{ |sum, shr| sum || shr}

        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(shared).to be_truthy
      end
    end

    context 'authorized user without master privileges' do
      it "should not return project's runners" do
        get api("/projects/#{project.id}/runners", user2)

        expect(response.status).to eq(403)
      end
    end

    context 'unauthorized user' do
      it "should not return project's runners" do
        get api("/projects/#{project.id}/runners")

        expect(response.status).to eq(401)
      end
    end
  end

  describe 'PUT /projects/:id/runners/:runner_id' do
    context 'authorized user' do
      it 'should enable specific runner' do
        expect do
          put api("/projects/#{project.id}/runners/#{specific_runner2.id}", user)
        end.to change{ project.runners.count }.by(+1)
        expect(response.status).to eq(200)
      end

      it 'should avoid changes when enabling already enabled runner' do
        expect do
          put api("/projects/#{project.id}/runners/#{specific_runner.id}", user)
        end.to change{ project.runners.count }.by(0)
        expect(response.status).to eq(200)
      end

      it 'should not enable shared runner' do
        put api("/projects/#{project.id}/runners/#{shared_runner.id}", user)

        expect(response.status).to eq(403)
      end

      context 'user is admin' do
        it 'should enable any specific runner' do
          expect do
            put api("/projects/#{project.id}/runners/#{unused_specific_runner.id}", admin)
          end.to change{ project.runners.count }.by(+1)
          expect(response.status).to eq(200)
        end
      end

      context 'user is not admin' do
        it 'should not enable runner without access to' do
          put api("/projects/#{project.id}/runners/#{unused_specific_runner.id}", user)

          expect(response.status).to eq(403)
        end
      end
    end

    context 'authorized user without permissions' do
      it 'should not enable runner' do
        put api("/projects/#{project.id}/runners/#{specific_runner2.id}", user2)

        expect(response.status).to eq(403)
      end
    end

    context 'unauthorized user' do
      it 'should not enable runner' do
        put api("/projects/#{project.id}/runners/#{specific_runner2.id}")

        expect(response.status).to eq(401)
      end
    end
  end

  describe 'DELETE /projects/:id/runners/:runner_id' do
    context 'authorized user' do
      context 'when runner have more than one associated projects' do
        it "should disable project's runner" do
          expect do
            delete api("/projects/#{project.id}/runners/#{two_projects_runner.id}", user)
          end.to change{ project.runners.count }.by(-1)
          expect(response.status).to eq(200)
        end
      end

      context 'when runner have one associated projects' do
        it "should not disable project's runner" do
          expect do
            delete api("/projects/#{project.id}/runners/#{specific_runner.id}", user)
          end.to change{ project.runners.count }.by(0)
          expect(response.status).to eq(403)
        end
      end

      it 'should return 404 is runner is not found' do
        delete api("/projects/#{project.id}/runners/9999", user)

        expect(response.status).to eq(404)
      end
    end

    context 'authorized user without permissions' do
      it "should not disable project's runner" do
        delete api("/projects/#{project.id}/runners/#{specific_runner.id}", user2)

        expect(response.status).to eq(403)
      end
    end

    context 'unauthorized user' do
      it "should not disable project's runner" do
        delete api("/projects/#{project.id}/runners/#{specific_runner.id}")

        expect(response.status).to eq(401)
      end
    end
  end
end
