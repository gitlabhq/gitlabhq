require 'spec_helper'

describe API::Runners do
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
      it 'returns user available runners' do
        get api('/runners', user)

        shared = json_response.any? { |r| r['is_shared'] }
        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(shared).to be_falsey
      end

      it 'filters runners by scope' do
        get api('/runners?scope=active', user)

        shared = json_response.any? { |r| r['is_shared'] }
        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(shared).to be_falsey
      end

      it 'avoids filtering if scope is invalid' do
        get api('/runners?scope=unknown', user)
        expect(response).to have_gitlab_http_status(400)
      end
    end

    context 'unauthorized user' do
      it 'does not return runners' do
        get api('/runners')

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'GET /runners/all' do
    context 'authorized user' do
      context 'with admin privileges' do
        it 'returns all runners' do
          get api('/runners/all', admin)

          shared = json_response.any? { |r| r['is_shared'] }
          expect(response).to have_gitlab_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(shared).to be_truthy
        end
      end

      context 'without admin privileges' do
        it 'does not return runners list' do
          get api('/runners/all', user)

          expect(response).to have_gitlab_http_status(403)
        end
      end

      it 'filters runners by scope' do
        get api('/runners/all?scope=specific', admin)

        shared = json_response.any? { |r| r['is_shared'] }
        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(shared).to be_falsey
      end

      it 'avoids filtering if scope is invalid' do
        get api('/runners?scope=unknown', admin)
        expect(response).to have_gitlab_http_status(400)
      end
    end

    context 'unauthorized user' do
      it 'does not return runners' do
        get api('/runners')

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'GET /runners/:id' do
    context 'admin user' do
      context 'when runner is shared' do
        it "returns runner's details" do
          get api("/runners/#{shared_runner.id}", admin)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['description']).to eq(shared_runner.description)
        end
      end

      context 'when runner is not shared' do
        it "returns runner's details" do
          get api("/runners/#{specific_runner.id}", admin)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['description']).to eq(specific_runner.description)
        end
      end

      it 'returns 404 if runner does not exists' do
        get api('/runners/9999', admin)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context "runner project's administrative user" do
      context 'when runner is not shared' do
        it "returns runner's details" do
          get api("/runners/#{specific_runner.id}", user)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['description']).to eq(specific_runner.description)
        end
      end

      context 'when runner is shared' do
        it "returns runner's details" do
          get api("/runners/#{shared_runner.id}", user)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['description']).to eq(shared_runner.description)
        end
      end
    end

    context 'other authorized user' do
      it "does not return runner's details" do
        get api("/runners/#{specific_runner.id}", user2)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'unauthorized user' do
      it "does not return runner's details" do
        get api("/runners/#{specific_runner.id}")

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'PUT /runners/:id' do
    context 'admin user' do
      context 'when runner is shared' do
        it 'updates runner' do
          description = shared_runner.description
          active = shared_runner.active
          runner_queue_value = shared_runner.ensure_runner_queue_value

          update_runner(shared_runner.id, admin, description: "#{description}_updated",
                                                 active: !active,
                                                 tag_list: ['ruby2.1', 'pgsql', 'mysql'],
                                                 run_untagged: 'false',
                                                 locked: 'true',
                                                 access_level: 'ref_protected')
          shared_runner.reload

          expect(response).to have_gitlab_http_status(200)
          expect(shared_runner.description).to eq("#{description}_updated")
          expect(shared_runner.active).to eq(!active)
          expect(shared_runner.tag_list).to include('ruby2.1', 'pgsql', 'mysql')
          expect(shared_runner.run_untagged?).to be(false)
          expect(shared_runner.locked?).to be(true)
          expect(shared_runner.ref_protected?).to be_truthy
          expect(shared_runner.ensure_runner_queue_value)
            .not_to eq(runner_queue_value)
        end
      end

      context 'when runner is not shared' do
        it 'updates runner' do
          description = specific_runner.description
          runner_queue_value = specific_runner.ensure_runner_queue_value

          update_runner(specific_runner.id, admin, description: 'test')
          specific_runner.reload

          expect(response).to have_gitlab_http_status(200)
          expect(specific_runner.description).to eq('test')
          expect(specific_runner.description).not_to eq(description)
          expect(specific_runner.ensure_runner_queue_value)
            .not_to eq(runner_queue_value)
        end
      end

      it 'returns 404 if runner does not exists' do
        update_runner(9999, admin, description: 'test')

        expect(response).to have_gitlab_http_status(404)
      end

      def update_runner(id, user, args)
        put api("/runners/#{id}", user), args
      end
    end

    context 'authorized user' do
      context 'when runner is shared' do
        it 'does not update runner' do
          put api("/runners/#{shared_runner.id}", user), description: 'test'

          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'when runner is not shared' do
        it 'does not update runner without access to it' do
          put api("/runners/#{specific_runner.id}", user2), description: 'test'

          expect(response).to have_gitlab_http_status(403)
        end

        it 'updates runner with access to it' do
          description = specific_runner.description
          put api("/runners/#{specific_runner.id}", admin), description: 'test'
          specific_runner.reload

          expect(response).to have_gitlab_http_status(200)
          expect(specific_runner.description).to eq('test')
          expect(specific_runner.description).not_to eq(description)
        end
      end
    end

    context 'unauthorized user' do
      it 'does not delete runner' do
        put api("/runners/#{specific_runner.id}")

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'DELETE /runners/:id' do
    context 'admin user' do
      context 'when runner is shared' do
        it 'deletes runner' do
          expect do
            delete api("/runners/#{shared_runner.id}", admin)

            expect(response).to have_gitlab_http_status(204)
          end.to change { Ci::Runner.shared.count }.by(-1)
        end

        it_behaves_like '412 response' do
          let(:request) { api("/runners/#{shared_runner.id}", admin) }
        end
      end

      context 'when runner is not shared' do
        it 'deletes unused runner' do
          expect do
            delete api("/runners/#{unused_specific_runner.id}", admin)

            expect(response).to have_gitlab_http_status(204)
          end.to change { Ci::Runner.specific.count }.by(-1)
        end

        it 'deletes used runner' do
          expect do
            delete api("/runners/#{specific_runner.id}", admin)

            expect(response).to have_gitlab_http_status(204)
          end.to change { Ci::Runner.specific.count }.by(-1)
        end
      end

      it 'returns 404 if runner does not exists' do
        delete api('/runners/9999', admin)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'authorized user' do
      context 'when runner is shared' do
        it 'does not delete runner' do
          delete api("/runners/#{shared_runner.id}", user)
          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'when runner is not shared' do
        it 'does not delete runner without access to it' do
          delete api("/runners/#{specific_runner.id}", user2)
          expect(response).to have_gitlab_http_status(403)
        end

        it 'does not delete runner with more than one associated project' do
          delete api("/runners/#{two_projects_runner.id}", user)
          expect(response).to have_gitlab_http_status(403)
        end

        it 'deletes runner for one owned project' do
          expect do
            delete api("/runners/#{specific_runner.id}", user)

            expect(response).to have_gitlab_http_status(204)
          end.to change { Ci::Runner.specific.count }.by(-1)
        end

        it_behaves_like '412 response' do
          let(:request) { api("/runners/#{specific_runner.id}", user) }
        end
      end
    end

    context 'unauthorized user' do
      it 'does not delete runner' do
        delete api("/runners/#{specific_runner.id}")

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'GET /runners/:id/jobs' do
    set(:job_1) { create(:ci_build) }
    let!(:job_2) { create(:ci_build, :running, runner: shared_runner, project: project) }
    let!(:job_3) { create(:ci_build, :failed, runner: shared_runner, project: project) }
    let!(:job_4) { create(:ci_build, :running, runner: specific_runner, project: project) }
    let!(:job_5) { create(:ci_build, :failed, runner: specific_runner, project: project) }

    context 'admin user' do
      context 'when runner exists' do
        context 'when runner is shared' do
          it 'return jobs' do
            get api("/runners/#{shared_runner.id}/jobs", admin)

            expect(response).to have_gitlab_http_status(200)
            expect(response).to include_pagination_headers

            expect(json_response).to be_an(Array)
            expect(json_response.length).to eq(2)
          end
        end

        context 'when runner is specific' do
          it 'return jobs' do
            get api("/runners/#{specific_runner.id}/jobs", admin)

            expect(response).to have_gitlab_http_status(200)
            expect(response).to include_pagination_headers

            expect(json_response).to be_an(Array)
            expect(json_response.length).to eq(2)
          end
        end

        context 'when valid status is provided' do
          it 'return filtered jobs' do
            get api("/runners/#{specific_runner.id}/jobs?status=failed", admin)

            expect(response).to have_gitlab_http_status(200)
            expect(response).to include_pagination_headers

            expect(json_response).to be_an(Array)
            expect(json_response.length).to eq(1)
            expect(json_response.first).to include('id' => job_5.id)
          end
        end

        context 'when invalid status is provided' do
          it 'return 400' do
            get api("/runners/#{specific_runner.id}/jobs?status=non-existing", admin)

            expect(response).to have_gitlab_http_status(400)
          end
        end
      end

      context "when runner doesn't exist" do
        it 'returns 404' do
          get api('/runners/9999/jobs', admin)

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context "runner project's administrative user" do
      context 'when runner exists' do
        context 'when runner is shared' do
          it 'returns 403' do
            get api("/runners/#{shared_runner.id}/jobs", user)

            expect(response).to have_gitlab_http_status(403)
          end
        end

        context 'when runner is specific' do
          it 'return jobs' do
            get api("/runners/#{specific_runner.id}/jobs", user)

            expect(response).to have_gitlab_http_status(200)
            expect(response).to include_pagination_headers

            expect(json_response).to be_an(Array)
            expect(json_response.length).to eq(2)
          end
        end

        context 'when valid status is provided' do
          it 'return filtered jobs' do
            get api("/runners/#{specific_runner.id}/jobs?status=failed", user)

            expect(response).to have_gitlab_http_status(200)
            expect(response).to include_pagination_headers

            expect(json_response).to be_an(Array)
            expect(json_response.length).to eq(1)
            expect(json_response.first).to include('id' => job_5.id)
          end
        end

        context 'when invalid status is provided' do
          it 'return 400' do
            get api("/runners/#{specific_runner.id}/jobs?status=non-existing", user)

            expect(response).to have_gitlab_http_status(400)
          end
        end
      end

      context "when runner doesn't exist" do
        it 'returns 404' do
          get api('/runners/9999/jobs', user)

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'other authorized user' do
      it 'does not return jobs' do
        get api("/runners/#{specific_runner.id}/jobs", user2)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'unauthorized user' do
      it 'does not return jobs' do
        get api("/runners/#{specific_runner.id}/jobs")

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'GET /projects/:id/runners' do
    context 'authorized user with master privileges' do
      it "returns project's runners" do
        get api("/projects/#{project.id}/runners", user)

        shared = json_response.any? { |r| r['is_shared'] }
        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(shared).to be_truthy
      end
    end

    context 'authorized user without master privileges' do
      it "does not return project's runners" do
        get api("/projects/#{project.id}/runners", user2)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'unauthorized user' do
      it "does not return project's runners" do
        get api("/projects/#{project.id}/runners")

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'POST /projects/:id/runners' do
    context 'authorized user' do
      let(:specific_runner2) do
        create(:ci_runner).tap do |runner|
          create(:ci_runner_project, runner: runner, project: project2)
        end
      end

      it 'enables specific runner' do
        expect do
          post api("/projects/#{project.id}/runners", user), runner_id: specific_runner2.id
        end.to change { project.runners.count }.by(+1)
        expect(response).to have_gitlab_http_status(201)
      end

      it 'avoids changes when enabling already enabled runner' do
        expect do
          post api("/projects/#{project.id}/runners", user), runner_id: specific_runner.id
        end.to change { project.runners.count }.by(0)
        expect(response).to have_gitlab_http_status(409)
      end

      it 'does not enable locked runner' do
        specific_runner2.update(locked: true)

        expect do
          post api("/projects/#{project.id}/runners", user), runner_id: specific_runner2.id
        end.to change { project.runners.count }.by(0)

        expect(response).to have_gitlab_http_status(403)
      end

      it 'does not enable shared runner' do
        post api("/projects/#{project.id}/runners", user), runner_id: shared_runner.id

        expect(response).to have_gitlab_http_status(403)
      end

      context 'user is admin' do
        it 'enables any specific runner' do
          expect do
            post api("/projects/#{project.id}/runners", admin), runner_id: unused_specific_runner.id
          end.to change { project.runners.count }.by(+1)
          expect(response).to have_gitlab_http_status(201)
        end
      end

      context 'user is not admin' do
        it 'does not enable runner without access to' do
          post api("/projects/#{project.id}/runners", user), runner_id: unused_specific_runner.id

          expect(response).to have_gitlab_http_status(403)
        end
      end

      it 'raises an error when no runner_id param is provided' do
        post api("/projects/#{project.id}/runners", admin)

        expect(response).to have_gitlab_http_status(400)
      end
    end

    context 'authorized user without permissions' do
      it 'does not enable runner' do
        post api("/projects/#{project.id}/runners", user2)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'unauthorized user' do
      it 'does not enable runner' do
        post api("/projects/#{project.id}/runners")

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'DELETE /projects/:id/runners/:runner_id' do
    context 'authorized user' do
      context 'when runner have more than one associated projects' do
        it "disables project's runner" do
          expect do
            delete api("/projects/#{project.id}/runners/#{two_projects_runner.id}", user)

            expect(response).to have_gitlab_http_status(204)
          end.to change { project.runners.count }.by(-1)
        end

        it_behaves_like '412 response' do
          let(:request) { api("/projects/#{project.id}/runners/#{two_projects_runner.id}", user) }
        end
      end

      context 'when runner have one associated projects' do
        it "does not disable project's runner" do
          expect do
            delete api("/projects/#{project.id}/runners/#{specific_runner.id}", user)
          end.to change { project.runners.count }.by(0)
          expect(response).to have_gitlab_http_status(403)
        end
      end

      it 'returns 404 is runner is not found' do
        delete api("/projects/#{project.id}/runners/9999", user)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'authorized user without permissions' do
      it "does not disable project's runner" do
        delete api("/projects/#{project.id}/runners/#{specific_runner.id}", user2)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'unauthorized user' do
      it "does not disable project's runner" do
        delete api("/projects/#{project.id}/runners/#{specific_runner.id}")

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end
end
