# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ci:job_tokens rake tasks', feature_category: :permissions do
  let(:task_class) { Tasks::Ci::JobTokensTask }
  let(:task) { instance_double(task_class) }

  before do
    Rake.application.rake_require('tasks/ci/job_tokens')
  end

  describe 'check_policies' do
    it 'invokes the check methods of Ci::JobTokensTask' do
      expect(task_class).to receive(:new).and_return(task)

      expect(task).to receive(:check_policies_completeness)
      expect(task).to receive(:check_policies_correctness)
      expect(task).to receive(:check_docs)

      run_rake_task('ci:job_tokens:check_policies')
    end
  end

  describe 'check_policies_completeness' do
    it 'invokes the check_policies_completeness method of Ci::JobTokensTask' do
      expect(task_class).to receive(:new).and_return(task)

      expect(task).to receive(:check_policies_completeness)

      run_rake_task('ci:job_tokens:check_policies_completeness')
    end
  end

  describe 'check_policies_correctness' do
    it 'invokes the check_policies_correctness method of Ci::JobTokensTask' do
      expect(task_class).to receive(:new).and_return(task)

      expect(task).to receive(:check_policies_correctness)

      run_rake_task('ci:job_tokens:check_policies_correctness')
    end
  end

  describe 'check_docs' do
    it 'invokes the check_docs method of Ci::JobTokensTask' do
      expect(task_class).to receive(:new).and_return(task)

      expect(task).to receive(:check_docs)

      run_rake_task('ci:job_tokens:check_docs')
    end
  end

  describe 'compile_docs' do
    it 'invokes the compile_docs method of Ci::JobTokensTask' do
      expect(task_class).to receive(:new).and_return(task)

      expect(task).to receive(:compile_docs)

      run_rake_task('ci:job_tokens:compile_docs')
    end
  end
end
