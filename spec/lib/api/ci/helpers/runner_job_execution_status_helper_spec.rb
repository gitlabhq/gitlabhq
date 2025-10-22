# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Helpers::RunnerJobExecutionStatusHelper, feature_category: :runner_core do
  include described_class

  describe '#lazy_job_execution_status' do
    shared_examples 'job execution status behavior' do |factory_name, build_association|
      let_it_be(:runners_with_executing_builds) { create_list(factory_name, 2) }
      let_it_be(:runners_without_executing_builds) { create_list(factory_name, 2) }
      let_it_be(:runners_with_completed_builds) { create_list(factory_name, 2) }

      before_all do
        runners_with_executing_builds.each do |runner|
          create(:ci_build, :running, build_association => runner)
        end

        runners_with_completed_builds.each do |runner|
          create(:ci_build, :success, build_association => runner)
        end
      end

      context 'with executing builds' do
        subject do
          runners_with_executing_builds.map do |runner|
            lazy_job_execution_status(object: runner, key: 'test')
          end
        end

        it 'returns :active for runners with executing builds' do
          is_expected.to all(eq(:active))
        end

        it 'batches queries efficiently' do
          expect(runners_with_executing_builds.first.class).to receive(:id_in).once.and_call_original
          is_expected.to all(eq(:active))
        end
      end

      context 'with no executing builds' do
        subject do
          runners_without_executing_builds.map do |runner|
            lazy_job_execution_status(object: runner, key: 'test')
          end
        end

        it 'returns :idle for all runners' do
          is_expected.to all(eq(:idle))
        end
      end

      context 'with only completed builds' do
        subject do
          runners_with_completed_builds.map do |runner|
            lazy_job_execution_status(object: runner, key: 'test')
          end
        end

        it 'returns :idle for runners with only completed builds' do
          is_expected.to all(eq(:idle))
        end
      end
    end

    [
      ['runners', :ci_runner, :runner],
      ['runner managers', :ci_runner_machine, :runner_manager]
    ].each do |description, factory_name, build_association|
      context "when #{description}" do
        it_behaves_like 'job execution status behavior', factory_name, build_association
      end
    end
  end
end
