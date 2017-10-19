require 'spec_helper'

describe API::V3::Runners do
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
    create(:project_member, :reporter, user: user2, project: project)
  end

  describe 'DELETE /runners/:id' do
    context 'admin user' do
      context 'when runner is shared' do
        it 'deletes runner' do
          expect do
            delete v3_api("/runners/#{shared_runner.id}", admin)

            expect(response).to have_gitlab_http_status(200)
          end.to change { Ci::Runner.shared.count }.by(-1)
        end
      end

      context 'when runner is not shared' do
        it 'deletes unused runner' do
          expect do
            delete v3_api("/runners/#{unused_specific_runner.id}", admin)

            expect(response).to have_gitlab_http_status(200)
          end.to change { Ci::Runner.specific.count }.by(-1)
        end

        it 'deletes used runner' do
          expect do
            delete v3_api("/runners/#{specific_runner.id}", admin)

            expect(response).to have_gitlab_http_status(200)
          end.to change { Ci::Runner.specific.count }.by(-1)
        end
      end

      it 'returns 404 if runner does not exists' do
        delete v3_api('/runners/9999', admin)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'authorized user' do
      context 'when runner is shared' do
        it 'does not delete runner' do
          delete v3_api("/runners/#{shared_runner.id}", user)
          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'when runner is not shared' do
        it 'does not delete runner without access to it' do
          delete v3_api("/runners/#{specific_runner.id}", user2)
          expect(response).to have_gitlab_http_status(403)
        end

        it 'does not delete runner with more than one associated project' do
          delete v3_api("/runners/#{two_projects_runner.id}", user)
          expect(response).to have_gitlab_http_status(403)
        end

        it 'deletes runner for one owned project' do
          expect do
            delete v3_api("/runners/#{specific_runner.id}", user)

            expect(response).to have_gitlab_http_status(200)
          end.to change { Ci::Runner.specific.count }.by(-1)
        end
      end
    end

    context 'unauthorized user' do
      it 'does not delete runner' do
        delete v3_api("/runners/#{specific_runner.id}")

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'DELETE /projects/:id/runners/:runner_id' do
    context 'authorized user' do
      context 'when runner have more than one associated projects' do
        it "disables project's runner" do
          expect do
            delete v3_api("/projects/#{project.id}/runners/#{two_projects_runner.id}", user)

            expect(response).to have_gitlab_http_status(200)
          end.to change { project.runners.count }.by(-1)
        end
      end

      context 'when runner have one associated projects' do
        it "does not disable project's runner" do
          expect do
            delete v3_api("/projects/#{project.id}/runners/#{specific_runner.id}", user)
          end.to change { project.runners.count }.by(0)
          expect(response).to have_gitlab_http_status(403)
        end
      end

      it 'returns 404 is runner is not found' do
        delete v3_api("/projects/#{project.id}/runners/9999", user)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'authorized user without permissions' do
      it "does not disable project's runner" do
        delete v3_api("/projects/#{project.id}/runners/#{specific_runner.id}", user2)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'unauthorized user' do
      it "does not disable project's runner" do
        delete v3_api("/projects/#{project.id}/runners/#{specific_runner.id}")

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end
end
