# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::AfterRequeueJobService, :sidekiq_inline do
  let_it_be(:project) { create(:project, :empty_repo) }
  let_it_be(:user) { project.first_owner }

  before_all do
    project.repository.create_file(user, 'init', 'init', message: 'init', branch_name: 'master')
  end

  subject(:service) { described_class.new(project, user) }

  context 'stage-dag mixed pipeline' do
    let(:config) do
      <<-EOY
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
      EOY
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
        b1: 'pending',
        b2: 'created',
        c1: 'created',
        c2: 'created'
      )

      b1.success!
      check_jobs_statuses(
        a1: 'pending',
        a2: 'created',
        b1: 'success',
        b2: 'created',
        c1: 'created',
        c2: 'created'
      )

      a1.drop!
      check_jobs_statuses(
        a1: 'failed',
        a2: 'skipped',
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
        b1: 'success',
        b2: 'created',
        c1: 'created',
        c2: 'created'
      )
    end
  end

  context 'stage-dag mixed pipeline with some same-stage needs' do
    let(:config) do
      <<-EOY
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
      EOY
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

  def execute_after_requeue_service(processable)
    service.execute(processable)
  end
end
