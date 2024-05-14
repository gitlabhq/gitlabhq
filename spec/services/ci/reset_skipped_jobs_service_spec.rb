# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ResetSkippedJobsService, :sidekiq_inline, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :empty_repo) }
  let_it_be(:user) { project.first_owner }

  let(:pipeline) do
    Ci::CreatePipelineService.new(project, user, { ref: 'master' }).execute(:push).payload
  end

  let(:a1) { find_job('a1') }
  let(:a2) { find_job('a2') }
  let(:b1) { find_job('b1') }
  let(:input_processables) { a1 } # This is the input used when running service.execute()

  before_all do
    project.repository.create_file(user, 'init', 'init', message: 'init', branch_name: 'master')
  end

  subject(:service) { described_class.new(project, user) }

  shared_examples 'with a stage-dag mixed pipeline' do
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
      service.execute(input_processables)

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
      let(:retryer) { create(:user, maintainer_of: project) }
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

        service.execute(input_processables)

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

  shared_examples 'with stage-dag mixed pipeline with some same-stage needs' do
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
      service.execute(input_processables)

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

  shared_examples 'with same-stage needs' do
    let(:config) do
      <<-YAML
      a1:
        script: exit $(($RANDOM % 2))

      b1:
        script: exit 0
        needs: [a1]

      c1:
        script: exit 0
        needs: [b1]
      YAML
    end

    before do
      stub_ci_pipeline_yaml_file(config)
      check_jobs_statuses(
        a1: 'pending',
        b1: 'created',
        c1: 'created'
      )

      a1.drop!
      check_jobs_statuses(
        a1: 'failed',
        b1: 'skipped',
        c1: 'skipped'
      )

      new_a1 = Ci::RetryJobService.new(project, user).clone!(a1)
      new_a1.enqueue!
      check_jobs_statuses(
        a1: 'pending',
        b1: 'skipped',
        c1: 'skipped'
      )
    end

    it 'marks subsequent skipped jobs as processable' do
      service.execute(input_processables)

      check_jobs_statuses(
        a1: 'pending',
        b1: 'created',
        c1: 'created'
      )
    end
  end

  context 'with same-stage needs where the parent jobs do not share the same descendants' do
    let(:config) do
      <<-YAML
      a1:
        script: exit $(($RANDOM % 2))

      a2:
        script: exit $(($RANDOM % 2))

      b1:
        script: exit 0
        needs: [a1]

      b2:
        script: exit 0
        needs: [a2]

      c1:
        script: exit 0
        needs: [b1]

      c2:
        script: exit 0
        needs: [b2]
      YAML
    end

    before do
      stub_ci_pipeline_yaml_file(config)
      check_jobs_statuses(
        a1: 'pending',
        a2: 'pending',
        b1: 'created',
        b2: 'created',
        c1: 'created',
        c2: 'created'
      )

      a1.drop!
      a2.drop!

      check_jobs_statuses(
        a1: 'failed',
        a2: 'failed',
        b1: 'skipped',
        b2: 'skipped',
        c1: 'skipped',
        c2: 'skipped'
      )

      new_a1 = Ci::RetryJobService.new(project, user).clone!(a1)
      new_a1.enqueue!

      check_jobs_statuses(
        a1: 'pending',
        a2: 'failed',
        b1: 'skipped',
        b2: 'skipped',
        c1: 'skipped',
        c2: 'skipped'
      )

      new_a2 = Ci::RetryJobService.new(project, user).clone!(a2)
      new_a2.enqueue!

      check_jobs_statuses(
        a1: 'pending',
        a2: 'pending',
        b1: 'skipped',
        b2: 'skipped',
        c1: 'skipped',
        c2: 'skipped'
      )
    end

    # This demonstrates that when only a1 is inputted, only the *1 subsequent jobs are reset.
    # This is in contrast to the following example when both a1 and a2 are inputted.
    it 'marks subsequent skipped jobs as processable' do
      service.execute(input_processables)

      check_jobs_statuses(
        a1: 'pending',
        a2: 'pending',
        b1: 'created',
        b2: 'skipped',
        c1: 'created',
        c2: 'skipped'
      )
    end

    context 'when multiple processables are inputted' do
      # When both a1 and a2 are inputted, all subsequent jobs are reset.
      it 'marks subsequent skipped jobs as processable' do
        input_processables = [a1, a2]
        service.execute(input_processables)

        check_jobs_statuses(
          a1: 'pending',
          a2: 'pending',
          b1: 'created',
          b2: 'created',
          c1: 'created',
          c2: 'created'
        )
      end
    end
  end

  context 'when a single processable is inputted' do
    it_behaves_like 'with a stage-dag mixed pipeline'
    it_behaves_like 'with stage-dag mixed pipeline with some same-stage needs'
    it_behaves_like 'with same-stage needs'
  end

  context 'when multiple processables are inputted' do
    let(:input_processables) { [a1, b1] }

    it_behaves_like 'with a stage-dag mixed pipeline'
    it_behaves_like 'with stage-dag mixed pipeline with some same-stage needs'
    it_behaves_like 'with same-stage needs'
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
end
