# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::ProcessBuildService, '#execute', feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, maintainers: user) }
  let_it_be(:pipeline) { create(:ci_pipeline, ref: 'master', project: project) }

  subject { described_class.new(project, user).execute(build, current_status) }

  shared_context 'with enqueue_immediately set' do
    before do
      build.set_enqueue_immediately!
    end
  end

  context 'for single build' do
    let!(:build) { create(:ci_build, *[trait].compact, :created, **conditions, pipeline: pipeline) }

    where(:trait, :conditions, :current_status, :after_status, :retry_after_status) do
      nil          | { when: :on_success } | 'success' | 'pending'   | 'pending'
      nil          | { when: :on_success } | 'skipped' | 'pending'   | 'pending'
      nil          | { when: :on_success } | 'failed'  | 'skipped'   | 'skipped'
      nil          | { when: :on_failure } | 'success' | 'skipped'   | 'skipped'
      nil          | { when: :on_failure } | 'skipped' | 'skipped'   | 'skipped'
      nil          | { when: :on_failure } | 'failed'  | 'pending'   | 'pending'
      nil          | { when: :always }     | 'success' | 'pending'   | 'pending'
      nil          | { when: :always }     | 'skipped' | 'pending'   | 'pending'
      nil          | { when: :always }     | 'failed'  | 'pending'   | 'pending'
      :actionable  | { when: :manual }     | 'success' | 'manual'    | 'pending'
      :actionable  | { when: :manual }     | 'skipped' | 'manual'    | 'pending'
      :actionable  | { when: :manual }     | 'failed'  | 'skipped'   | 'skipped'
      :schedulable | { when: :delayed }    | 'success' | 'scheduled' | 'pending'
      :schedulable | { when: :delayed }    | 'skipped' | 'scheduled' | 'pending'
      :schedulable | { when: :delayed }    | 'failed'  | 'skipped'   | 'skipped'
    end

    with_them do
      it 'updates the job status to after_status' do
        expect { subject }.to change { build.status }.to(after_status)
      end

      context 'when build is set to enqueue immediately' do
        include_context 'with enqueue_immediately set'

        it 'updates the job status to retry_after_status' do
          expect { subject }.to change { build.status }.to(retry_after_status)
        end
      end
    end
  end

  context 'when build is scheduled with DAG' do
    let!(:build) do
      create(
        :ci_build,
        *[trait].compact,
        :dependent,
        :created,
        when: build_when,
        pipeline: pipeline,
        needed: other_build
      )
    end

    let!(:other_build) { create(:ci_build, :created, when: :on_success, pipeline: pipeline) }

    where(:trait, :build_when, :current_status, :after_status, :retry_after_status) do
      nil          | :on_success | 'success' | 'pending'   | 'pending'
      nil          | :on_success | 'skipped' | 'skipped'   | 'skipped'
      nil          | :manual     | 'success' | 'manual'    | 'pending'
      nil          | :manual     | 'skipped' | 'skipped'   | 'skipped'
      nil          | :delayed    | 'success' | 'manual'    | 'pending'
      nil          | :delayed    | 'skipped' | 'skipped'   | 'skipped'
      :schedulable | :delayed    | 'success' | 'scheduled' | 'pending'
      :schedulable | :delayed    | 'skipped' | 'skipped'   | 'skipped'
    end

    with_them do
      it 'updates the job status to after_status' do
        expect { subject }.to change { build.status }.to(after_status)
      end

      context 'when build is set to enqueue immediately' do
        include_context 'with enqueue_immediately set'

        it 'updates the job status to retry_after_status' do
          expect { subject }.to change { build.status }.to(retry_after_status)
        end
      end
    end
  end
end
