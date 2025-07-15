# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Builds::TimeoutCalculator, feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { FactoryBot.build(:project) }
  let_it_be(:runner) { FactoryBot.build(:ci_runner) }
  let_it_be(:build) { FactoryBot.build(:ci_build, project: project, runner: runner) }
  let(:calculator) { described_class.new(build) }

  describe '#applicable_timeout' do
    where(:job_timeout, :project_timeout, :runner_timeout, :result_value, :result_source) do
      100 | 200 | 300 | 100 | :job_timeout_source
      100 | nil | 300 | 100 | :job_timeout_source
      100 | 50  | 300 | 100 | :job_timeout_source
      100 | 50  | nil | 100 | :job_timeout_source
      nil | 200 | 300 | 200 | :project_timeout_source
      nil | 200 | nil | 200 | :project_timeout_source
      100 | 200 | 50  | 50  | :runner_timeout_source
      nil | 200 | 100 | 100 | :runner_timeout_source
      nil | nil | 100 | 100 | :runner_timeout_source
      nil | nil | nil | nil | nil
    end

    with_them do
      before do
        allow(build).to receive(:options).and_return({ job_timeout: job_timeout })
        allow(project).to receive(:build_timeout).and_return(project_timeout)
        allow(runner).to receive(:maximum_timeout).and_return(runner_timeout)
      end

      it 'calculates correct timeout' do
        result = calculator.applicable_timeout

        if result_value.nil? && result_source.nil?
          expect(result).to be_nil
        else
          expect(result).to be_a(Ci::Builds::Timeout)
          expect(result.value).to eq(result_value)
          expect(result.source).to eq(described_class.timeout_sources.fetch(result_source))
        end
      end
    end
  end
end
