# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ResetSkippedJobsService, :sidekiq_inline, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :empty_repo) }
  let_it_be(:user) { project.first_owner }

  before_all do
    project.repository.create_file(user, 'init', 'init', message: 'init', branch_name: 'master')
  end

  subject(:service) { described_class.new(project, user) }

  context 'with a stage-dag mixed pipeline' do
    let(:config) do
      <<-YAML
      stages: [a, b, c]

      a1:
        stage: a
        script: exit $(($RANDOM % 2))

      a2:
        stage: a
        script: exit 0
        needs: [a1]

      a3:
        stage: a
        script: exit 0
        needs: [a2]

      b1:
        stage: b
        script: exit 0
        needs: []

      b2:
        stage: b
        script: exit 0
        needs: [a2]

      c1:
        stage: c
        script: exit 0
        needs: [b2]

      c2:
        stage: c
        script: exit 0
      YAML
    end

    let(:pipeline) do
      Ci::CreatePipelineService.new(project, user, { ref: 'master' }).execute(:push).payload
    end

    let(:a1) { find_job('a1') }
    let(:b1) { find_job('b1') }

    before do
      stub_ci_pipeline_yaml_file(config)
      check_jobs_statuses(
        a1: 'pending',
        a2: 'created',
        a3: 'created',
        b1: 'pending',
        b2: 'created',
        c1: 'created',
        c2: 'created'
      )

      b1.success!
      check_jobs_statuses(
        a1: 'pending',
        a2: 'created',
        a3: 'created',
        b1: 'success',
        b2: 'created',
        c1: 'created',
        c2: 'created'
      )

      a1.drop!
      check_jobs_statuses(
        a1: 'failed',
        a2: 'skipped',
        a3: 'skipped',
        b1: 'success',
        b2: 'skipped',
        c1: 'skipped',
        c2: 'skipped'
      )

      new_a1 = Ci::RetryJobService.new(project, user).clone!(a1)
      new_a1.enqueue!
      check_jobs_statuses(
        a1: 'pending',
        a2: 'skipped',
        a3: 'skipped',
        b1: 'success',
        b2: 'skipped',
        c1: 'skipped',
        c2: 'skipped'
      )
    end

    it 'marks subsequent skipped jobs as processable' do
      execute_after_requeue_service(a1)

      check_jobs_statuses(
        a1: 'pending',
        a2: 'created',
        a3: 'created',
        b1: 'success',
        b2: 'created',
        c1: 'created',
        c2: 'created'
      )
    end

    context 'when executed by a different user than the original owner' do
      let(:retryer) { create(:user).tap { |u| project.add_maintainer(u) } }
      let(:service) { described_class.new(project, retryer) }

      it 'reassigns jobs with updated statuses to the retryer' do
        expect(jobs_name_status_owner_needs).to contain_exactly(
          { 'name' => 'a1', 'status' => 'pending', 'user_id' => user.id, 'needs' => [] },
          { 'name' => 'a2', 'status' => 'skipped', 'user_id' => user.id, 'needs' => ['a1'] },
          { 'name' => 'a3', 'status' => 'skipped', 'user_id' => user.id, 'needs' => ['a2'] },
          { 'name' => 'b1', 'status' => 'success', 'user_id' => user.id, 'needs' => [] },
          { 'name' => 'b2', 'status' => 'skipped', 'user_id' => user.id, 'needs' => ['a2'] },
          { 'name' => 'c1', 'status' => 'skipped', 'user_id' => user.id, 'needs' => ['b2'] },
          { 'name' => 'c2', 'status' => 'skipped', 'user_id' => user.id, 'needs' => [] }
        )

        execute_after_requeue_service(a1)

        expect(jobs_name_status_owner_needs).to contain_exactly(
          { 'name' => 'a1', 'status' => 'pending', 'user_id' => user.id,    'needs' => [] },
          { 'name' => 'a2', 'status' => 'created', 'user_id' => retryer.id, 'needs' => ['a1'] },
          { 'name' => 'a3', 'status' => 'created', 'user_id' => retryer.id, 'needs' => ['a2'] },
          { 'name' => 'b1', 'status' => 'success', 'user_id' => user.id,    'needs' => [] },
          { 'name' => 'b2', 'status' => 'created', 'user_id' => retryer.id, 'needs' => ['a2'] },
          { 'name' => 'c1', 'status' => 'created', 'user_id' => retryer.id, 'needs' => ['b2'] },
          { 'name' => 'c2', 'status' => 'created', 'user_id' => retryer.id, 'needs' => [] }
        )
      end
    end
  end

  context 'with stage-dag mixed pipeline with some same-stage needs' do
    let(:config) do
      <<-YAML
      stages: [a, b, c]

      a1:
        stage: a
        script: exit $(($RANDOM % 2))

      a2:
        stage: a
        script: exit 0
        needs: [a1]

      b1:
        stage: b
        script: exit 0
        needs: [b2]

      b2:
        stage: b
        script: exit 0

      c1:
        stage: c
        script: exit 0
        needs: [b2]

      c2:
        stage: c
        script: exit 0
      YAML
    end

    let(:pipeline) do
      Ci::CreatePipelineService.new(project, user, { ref: 'master' }).execute(:push).payload
    end

    let(:a1) { find_job('a1') }

    before do
      stub_ci_pipeline_yaml_file(config)
      check_jobs_statuses(
        a1: 'pending',
        a2: 'created',
        b1: 'created',
        b2: 'created',
        c1: 'created',
        c2: 'created'
      )

      a1.drop!
      check_jobs_statuses(
        a1: 'failed',
        a2: 'skipped',
        b1: 'skipped',
        b2: 'skipped',
        c1: 'skipped',
        c2: 'skipped'
      )

      new_a1 = Ci::RetryJobService.new(project, user).clone!(a1)
      new_a1.enqueue!
      check_jobs_statuses(
        a1: 'pending',
        a2: 'skipped',
        b1: 'skipped',
        b2: 'skipped',
        c1: 'skipped',
        c2: 'skipped'
      )
    end

    it 'marks subsequent skipped jobs as processable' do
      execute_after_requeue_service(a1)

      check_jobs_statuses(
        a1: 'pending',
        a2: 'created',
        b1: 'created',
        b2: 'created',
        c1: 'created',
        c2: 'created'
      )
    end
  end

  context 'with same-stage needs' do
    let(:config) do
      <<-YAML
      a:
        script: exit $(($RANDOM % 2))

      b:
        script: exit 0
        needs: [a]

      c:
        script: exit 0
        needs: [b]
      YAML
    end

    let(:pipeline) do
      Ci::CreatePipelineService.new(project, user, { ref: 'master' }).execute(:push).payload
    end

    let(:a) { find_job('a') }

    before do
      stub_ci_pipeline_yaml_file(config)
      check_jobs_statuses(
        a: 'pending',
        b: 'created',
        c: 'created'
      )

      a.drop!
      check_jobs_statuses(
        a: 'failed',
        b: 'skipped',
        c: 'skipped'
      )

      new_a = Ci::RetryJobService.new(project, user).clone!(a)
      new_a.enqueue!
      check_jobs_statuses(
        a: 'pending',
        b: 'skipped',
        c: 'skipped'
      )
    end

    it 'marks subsequent skipped jobs as processable' do
      execute_after_requeue_service(a)

      check_jobs_statuses(
        a: 'pending',
        b: 'created',
        c: 'created'
      )
    end
  end

  private

  def find_job(name)
    processables.find_by!(name: name)
  end

  def check_jobs_statuses(statuses)
    expect(processables.order(:name).pluck(:name, :status)).to contain_exactly(*statuses.stringify_keys.to_a)
  end

  def processables
    pipeline.processables.latest
  end

  def jobs_name_status_owner_needs
    processables.reload.map do |job|
      job.attributes.slice('name', 'status', 'user_id').merge('needs' => job.needs.map(&:name))
    end
  end

  def execute_after_requeue_service(processable)
    service.execute(processable)
  end
end
