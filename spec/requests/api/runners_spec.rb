require 'spec_helper'

describe API::Runners, api: true  do
  include ApiHelpers

  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }

  let(:project) { create(:project, creator_id: user.id) }
  let(:project2) { create(:project, creator_id: user.id) }

  let!(:shared_runner) { create(:ci_runner, :shared) }
  let!(:unused_specific_runner) { create(:ci_runner) }

  let!(:specific_runner) do
    create(:ci_runner).tap do |runner|
      create(:ci_runner_project, runner: runner, project: project)
    end
  end

  let!(:two_projects_runner) do
    create(:ci_runner).tap do |runner|
      create(:ci_runner_project, runner: runner, project: project)
      create(:ci_runner_project, runner: runner, project: project2)
    end
  end

  before do
    # Set project access for users
    create(:project_member, :master, user: user, project: project)
    create(:project_member, :master, user: user, project: project2)
    create(:project_member, :reporter, user: user2, project: project)
  end

  describe 'GET /runners' do
    context 'authorized user' do
      it 'should return user available runners' do
        get api('/runners', user)
        shared = json_response.any?{ |r| r['is_shared'] }

        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(shared).to be_falsey
      end

      it 'should filter runners by scope' do
        get api('/runners?scope=active', user)
        shared = json_response.any?{ |r| r['is_shared'] }

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

  describe 'GET /runners/all' do
    context 'authorized user' do
      context 'with admin privileges' do
        it 'should return all runners' do
          get api('/runners/all', admin)
          shared = json_response.any?{ |r| r['is_shared'] }

          expect(response.status).to eq(200)
          expect(json_response).to be_an Array
          expect(shared).to be_truthy
        end
      end

      context 'without admin privileges' do
        it 'should not return runners list' do
          get api('/runners/all', user)

          expect(response.status).to eq(403)
        end
      end

      it 'should filter runners by scope' do
        get api('/runners/all?scope=specific', admin)
        shared = json_response.any?{ |r| r['is_shared'] }

        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(shared).to be_falsey
      end

      it 'should avoid filtering if scope is invalid' do
        get api('/runners?scope=unknown', admin)
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
      context 'when runner is shared' do
        it "should return runner's details" do
          get api("/runners/#{shared_runner.id}", admin)

          expect(response.status).to eq(200)
          expect(json_response['description']).to eq(shared_runner.description)
        end
      end

      context 'when runner is not shared' do
        it "should return runner's details" do
          get api("/runners/#{specific_runner.id}", admin)

          expect(response.status).to eq(200)
          expect(json_response['description']).to eq(specific_runner.description)
        end
      end

      it 'should return 404 if runner does not exists' do
        get api('/runners/9999', admin)

        expect(response.status).to eq(404)
      end
    end

    context "runner project's administrative user" do
      context 'when runner is not shared' do
        it "should return runner's details" do
          get api("/runners/#{specific_runner.id}", user)

          expect(response.status).to eq(200)
          expect(json_response['description']).to eq(specific_runner.description)
        end
      end

      context 'when runner is shared' do
        it "should return runner's details" do
          get api("/runners/#{shared_runner.id}", user)

          expect(response.status).to eq(200)
          expect(json_response['description']).to eq(shared_runner.description)
        end
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
      context 'when runner is shared' do
        it 'should update runner' do
          description = shared_runner.description
          active = shared_runner.active

          put api("/runners/#{shared_runner.id}", admin), description: "#{description}_updated", active: !active,
                                                          tag_list: ['ruby2.1', 'pgsql', 'mysql']
          shared_runner.reload

          expect(response.status).to eq(200)
          expect(shared_runner.description).to eq("#{description}_updated")
          expect(shared_runner.active).to eq(!active)
          expect(shared_runner.tag_list).to include('ruby2.1', 'pgsql', 'mysql')
        end
      end

      context 'when runner is not shared' do
        it 'should update runner' do
          description = specific_runner.description
          put api("/runners/#{specific_runner.id}", admin), description: 'test'
          specific_runner.reload

          expect(response.status).to eq(200)
          expect(specific_runner.description).to eq('test')
          expect(specific_runner.description).not_to eq(description)
        end
      end

      it 'should return 404 if runner does not exists' do
        put api('/runners/9999', admin), description: 'test'

        expect(response.status).to eq(404)
      end
    end

    context 'authorized user' do
      context 'when runner is shared' do
        it 'should not update runner' do
          put api("/runners/#{shared_runner.id}", user)

          expect(response.status).to eq(403)
        end
      end

      context 'when runner is not shared' do
        it 'should not update runner without access to it' do
          put api("/runners/#{specific_runner.id}", user2)

          expect(response.status).to eq(403)
        end

        it 'should update runner with access to it' do
          description = specific_runner.description
          put api("/runners/#{specific_runner.id}", admin), description: 'test'
          specific_runner.reload

          expect(response.status).to eq(200)
          expect(specific_runner.description).to eq('test')
          expect(specific_runner.description).not_to eq(description)
        end
      end
    end

    context 'unauthorized user' do
      it 'should not delete runner' do
        put api("/runners/#{specific_runner.id}")

        expect(response.status).to eq(401)
      end
    end
  end

  describe 'DELETE /runners/:id' do
    context 'admin user' do
      context 'when runner is shared' do
        it 'should delete runner' do
          expect do
            delete api("/runners/#{shared_runner.id}", admin)
          end.to change{ Ci::Runner.shared.count }.by(-1)
          expect(response.status).to eq(200)
        end
      end

      context 'when runner is not shared' do
        it 'should delete unused runner' do
          expect do
            delete api("/runners/#{unused_specific_runner.id}", admin)
          end.to change{ Ci::Runner.specific.count }.by(-1)
          expect(response.status).to eq(200)
        end

        it 'should delete used runner' do
          expect do
            delete api("/runners/#{specific_runner.id}", admin)
          end.to change{ Ci::Runner.specific.count }.by(-1)
          expect(response.status).to eq(200)
        end
      end

      it 'should return 404 if runner does not exists' do
        delete api('/runners/9999', admin)

        expect(response.status).to eq(404)
      end
    end

    context 'authorized user' do
      context 'when runner is shared' do
        it 'should not delete runner' do
          delete api("/runners/#{shared_runner.id}", user)
          expect(response.status).to eq(403)
        end
      end

      context 'when runner is not shared' do
        it 'should not delete runner without access to it' do
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
        shared = json_response.any?{ |r| r['is_shared'] }

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

  describe 'POST /projects/:id/runners' do
    context 'authorized user' do
      it 'should enable specific runner' do
        specific_runner2 = create(:ci_runner).tap do |runner|
          create(:ci_runner_project, runner: runner, project: project2)
        end

        expect do
          post api("/projects/#{project.id}/runners", user), runner_id: specific_runner2.id
        end.to change{ project.runners.count }.by(+1)
        expect(response.status).to eq(201)
      end

      it 'should avoid changes when enabling already enabled runner' do
        expect do
          post api("/projects/#{project.id}/runners", user), runner_id: specific_runner.id
        end.to change{ project.runners.count }.by(0)
        expect(response.status).to eq(201)
      end

      it 'should not enable shared runner' do
        post api("/projects/#{project.id}/runners", user), runner_id: shared_runner.id

        expect(response.status).to eq(403)
      end

      context 'user is admin' do
        it 'should enable any specific runner' do
          expect do
            post api("/projects/#{project.id}/runners", admin), runner_id: unused_specific_runner.id
          end.to change{ project.runners.count }.by(+1)
          expect(response.status).to eq(201)
        end
      end

      context 'user is not admin' do
        it 'should not enable runner without access to' do
          post api("/projects/#{project.id}/runners", user), runner_id: unused_specific_runner.id

          expect(response.status).to eq(403)
        end
      end

      it 'should raise an error when no runner_id param is provided' do
        post api("/projects/#{project.id}/runners", admin)

        expect(response.status).to eq(400)
      end
    end

    context 'authorized user without permissions' do
      it 'should not enable runner' do
        post api("/projects/#{project.id}/runners", user2)

        expect(response.status).to eq(403)
      end
    end

    context 'unauthorized user' do
      it 'should not enable runner' do
        post api("/projects/#{project.id}/runners")

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
