require 'spec_helper'

describe API::PipelineSchedules do
  let(:developer) { create(:user) }
  let(:user) { create(:user) }
  let!(:project) { create(:project, :repository) }

  before do
    project.add_developer(developer)
  end

  describe 'GET /projects/:id/pipeline_schedules' do
    context 'authenticated user with valid permissions' do
      before do
        create(:ci_pipeline_schedule, project: project, owner: developer)
          .tap do |pipeline_schedule|
          pipeline_schedule.pipelines << build(:ci_pipeline, project: project)
        end
      end

      it 'returns list of pipeline_schedules' do
        get api("/projects/#{project.id}/pipeline_schedules", developer)

        expect(response).to have_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(response).to match_response_schema('pipeline_schedules')
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not return pipeline_schedules list' do
        get api("/projects/#{project.id}/pipeline_schedules", user)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'unauthenticated user' do
      it 'does not return pipeline_schedules list' do
        get api("/projects/#{project.id}/pipeline_schedules")

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /projects/:id/pipeline_schedules/:pipeline_schedule_id' do
    let(:pipeline_schedule) do
      create(:ci_pipeline_schedule, project: project, owner: developer)
        .tap do |pipeline_schedule|
        pipeline_schedule.pipelines << build(:ci_pipeline, project: project)
      end
    end

    context 'authenticated user with valid permissions' do
      it 'returns pipeline_schedule details' do
        get api("/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}", developer)

        expect(response).to have_http_status(:ok)
        expect(response).to match_response_schema('pipeline_schedule')
      end

      it 'responds with 404 Not Found if requesting non-existing pipeline_schedule' do
        get api("/projects/#{project.id}/pipeline_schedules/-5", developer)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not return pipeline_schedules list' do
        get api("/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}", user)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'unauthenticated user' do
      it 'does not return pipeline_schedules list' do
        get api("/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}")

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /projects/:id/pipeline_schedules' do
    let(:description) { 'pipeline_schedule' }
    let(:ref) { 'master' }
    let(:cron) { '* * * * *' }
    let(:cron_timezone) { 'UTC' }
    let(:active) { true }

    context 'authenticated user with valid permissions' do
      context 'with required parameters' do
        it 'creates pipeline_schedule' do
          expect do
            post api("/projects/#{project.id}/pipeline_schedules", developer),
              description: description, ref: ref, cron: cron,
              cron_timezone: cron_timezone, active: active
          end
          .to change{project.pipeline_schedules.count}.by(1)

          expect(response).to have_http_status(:created)
          expect(response).to match_response_schema('pipeline_schedule')
          expect(json_response['description']).to eq(description)
          expect(json_response['ref']).to eq(ref)
          expect(json_response['cron']).to eq(cron)
          expect(json_response['cron_timezone']).to eq(cron_timezone)
          expect(json_response['active']).to eq(active)
        end
      end

      context 'without required parameters' do
        it 'does not create pipeline_schedule' do
          post api("/projects/#{project.id}/pipeline_schedules", developer)

          expect(response).to have_http_status(:bad_request)
        end
      end

      context 'when cron has validation error' do
        it 'does not create pipeline_schedule' do
          post api("/projects/#{project.id}/pipeline_schedules", developer),
            description: description, ref: ref, cron: 'invalid-cron',
            cron_timezone: cron_timezone, active: active

          expect(response).to have_http_status(:bad_request)
          expect(json_response['message']).to have_key('cron')
        end
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not create pipeline_schedule' do
        post api("/projects/#{project.id}/pipeline_schedules", user),
          description: description, ref: ref, cron: cron,
          cron_timezone: cron_timezone, active: active

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'unauthenticated user' do
      it 'does not create pipeline_schedule' do
        post api("/projects/#{project.id}/pipeline_schedules"),
          description: description, ref: ref, cron: cron,
          cron_timezone: cron_timezone, active: active

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /projects/:id/pipeline_schedules/:pipeline_schedule_id' do
    let(:pipeline_schedule) do
      create(:ci_pipeline_schedule, project: project, owner: developer)
    end

    context 'authenticated user with valid permissions' do
      let(:new_cron) { '1 2 3 4 *' }

      it 'updates cron' do
        put api("/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}", developer),
          cron: new_cron
        pipeline_schedule.reload

        expect(response).to have_http_status(:ok)
        expect(response).to match_response_schema('pipeline_schedule')
        expect(json_response['cron']).to eq(new_cron)
        expect(pipeline_schedule.next_run_at.min).to eq(1)
        expect(pipeline_schedule.next_run_at.hour).to eq(2)
        expect(pipeline_schedule.next_run_at.day).to eq(3)
        expect(pipeline_schedule.next_run_at.month).to eq(4)
      end

      context 'when cron has validation error' do
        it 'does not update pipeline_schedule' do
          put api("/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}", developer),
            cron: 'invalid-cron'

          expect(response).to have_http_status(:bad_request)
          expect(json_response['message']).to have_key('cron')
        end
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not update pipeline_schedule' do
        put api("/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}", user)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'unauthenticated user' do
      it 'does not update pipeline_schedule' do
        put api("/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}")

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /projects/:id/pipeline_schedules/:pipeline_schedule_id/take_ownership' do
    let(:pipeline_schedule) do
      create(:ci_pipeline_schedule, project: project, owner: developer)
    end

    context 'authenticated user with valid permissions' do
      let(:developer2) { create(:user) }

      before do
        project.add_developer(developer2)
      end

      it 'updates owner' do
        post api("/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}/take_ownership", developer2)
        pipeline_schedule.reload

        expect(response).to have_http_status(:ok)
        expect(response).to match_response_schema('pipeline_schedule')
        expect(pipeline_schedule.owner).to eq(developer2)
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not update owner' do
        post api("/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}/take_ownership", user)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'unauthenticated user' do
      it 'does not update owner' do
        post api("/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}/take_ownership")

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /projects/:id/pipeline_schedules/:pipeline_schedule_id' do
    let(:master) { create(:user) }

    let!(:pipeline_schedule) do
      create(:ci_pipeline_schedule, project: project, owner: developer)
    end

    before do
      project.add_master(master)
    end

    context 'authenticated user with valid permissions' do
      it 'deletes pipeline_schedule' do
        expect do
          delete api("/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}", master)
        end.to change{project.pipeline_schedules.count}.by(-1)

        expect(response).to have_http_status(:ok)
        expect(response).to match_response_schema('pipeline_schedule')
      end

      it 'responds with 404 Not Found if requesting non-existing pipeline_schedule' do
        delete api("/projects/#{project.id}/pipeline_schedules/-5", master)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not delete pipeline_schedule' do
        delete api("/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}", developer)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'unauthenticated user' do
      it 'does not delete pipeline_schedule' do
        delete api("/projects/#{project.id}/pipeline_schedules/#{pipeline_schedule.id}")

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
