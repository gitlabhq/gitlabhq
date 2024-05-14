# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Deleting Sidekiq jobs', :clean_gitlab_redis_queues, feature_category: :shared do
  include GraphqlHelpers

  let_it_be(:admin) { create(:admin) }

  let(:queue) { 'authorized_projects' }

  let(:variables) { { user: admin.username, worker_class: 'AuthorizedProjectsWorker', queue_name: queue } }
  let(:mutation) { graphql_mutation(:admin_sidekiq_queues_delete_jobs, variables) }

  def mutation_response
    graphql_mutation_response(:admin_sidekiq_queues_delete_jobs)
  end

  context 'when the user is not an admin' do
    let(:current_user) { create(:user) }

    it_behaves_like 'a mutation that returns top-level errors',
      errors: ['You must be an admin to use this mutation']
  end

  context 'when the user is an admin' do
    let(:current_user) { admin }

    context 'when valid request' do
      around do |example|
        Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
          Sidekiq::Queue.new(queue).clear
        end
        Sidekiq::Testing.disable!(&example)

        Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
          Sidekiq::Queue.new(queue).clear
        end
      end

      def add_job(user, args)
        Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
          Sidekiq::Client.push(
            'class' => 'AuthorizedProjectsWorker',
            'queue' => queue,
            'args' => args,
            'meta.user' => user.username
          )
          raise 'Not enqueued!' if Sidekiq::Queue.new(queue).size.zero? # rubocop:disable Style/ZeroLengthPredicate -- Sidekiq::Queue doesn't implement #blank? or #empty?
        end
      end

      it 'returns info about the deleted jobs' do
        add_job(admin, [1])
        add_job(admin, [2])
        add_job(create(:user), [3])

        post_graphql_mutation(mutation, current_user: admin)

        expect(mutation_response['errors']).to be_empty
        expect(mutation_response['result']).to eq('completed' => true, 'deletedJobs' => 2, 'queueSize' => 1)
      end
    end

    context 'when no required params are provided' do
      let(:variables) { { queue_name: queue } }

      it_behaves_like 'a mutation that returns errors in the response',
        errors: ['No metadata provided']
    end

    context 'when the queue does not exist' do
      let(:variables) { { user: admin.username, queue_name: 'authorized_projects_2' } }

      it_behaves_like 'a mutation that returns top-level errors',
        errors: ['Queue authorized_projects_2 not found']
    end
  end
end
