# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Admin::Sidekiq, :clean_gitlab_redis_queues, feature_category: :shared do
  let_it_be(:admin) { create(:admin) }

  describe 'DELETE /admin/sidekiq/queues/:queue_name' do
    context 'when the user is an admin' do
      around do |example|
        Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
          Sidekiq::Queue.new('authorized_projects').clear
        end

        Sidekiq::Testing.disable!(&example)

        Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
          Sidekiq::Queue.new('authorized_projects').clear
        end
      end

      def add_job(user, args)
        Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
          Sidekiq::Client.push(
            'class' => 'AuthorizedProjectsWorker',
            'queue' => 'authorized_projects',
            'args' => args,
            'meta.user' => user.username
          )
        end
      end

      context 'valid request' do
        before do
          add_job(admin, [1])
          add_job(admin, [2])
          add_job(create(:user), [3])
        end

        let_it_be(:path) { "/admin/sidekiq/queues/authorized_projects?user=#{admin.username}&worker_class=AuthorizedProjectsWorker" }

        it_behaves_like 'DELETE request permissions for admin mode' do
          let(:success_status_code) { :ok }
        end

        it 'returns info about the deleted jobs' do
          delete api(path, admin, admin_mode: true)

          expect(json_response).to eq('completed' => true, 'deleted_jobs' => 2, 'queue_size' => 1)
        end
      end

      context 'when no required params are provided' do
        it 'returns a 400' do
          delete api("/admin/sidekiq/queues/authorized_projects?user_2=#{admin.username}", admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when the queue does not exist' do
        it 'returns a 404' do
          delete api("/admin/sidekiq/queues/authorized_projects_2?user=#{admin.username}", admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
