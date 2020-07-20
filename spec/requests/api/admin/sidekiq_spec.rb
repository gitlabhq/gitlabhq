# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Admin::Sidekiq, :clean_gitlab_redis_queues do
  let_it_be(:admin) { create(:admin) }

  describe 'DELETE /admin/sidekiq/queues/:queue_name' do
    context 'when the user is not an admin' do
      it 'returns a 403' do
        delete api("/admin/sidekiq/queues/authorized_projects?user=#{admin.username}", create(:user))

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when the user is an admin' do
      around do |example|
        Sidekiq::Queue.new('authorized_projects').clear
        Sidekiq::Testing.disable!(&example)
        Sidekiq::Queue.new('authorized_projects').clear
      end

      def add_job(user, args)
        Sidekiq::Client.push(
          'class' => 'AuthorizedProjectsWorker',
          'queue' => 'authorized_projects',
          'args' => args,
          'meta.user' => user.username
        )
      end

      context 'valid request' do
        it 'returns info about the deleted jobs' do
          add_job(admin, [1])
          add_job(admin, [2])
          add_job(create(:user), [3])

          delete api("/admin/sidekiq/queues/authorized_projects?user=#{admin.username}", admin)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq('completed' => true,
                                      'deleted_jobs' => 2,
                                      'queue_size' => 1)
        end
      end

      context 'when no required params are provided' do
        it 'returns a 400' do
          delete api("/admin/sidekiq/queues/authorized_projects?user_2=#{admin.username}", admin)

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when the queue does not exist' do
        it 'returns a 404' do
          delete api("/admin/sidekiq/queues/authorized_projects_2?user=#{admin.username}", admin)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
