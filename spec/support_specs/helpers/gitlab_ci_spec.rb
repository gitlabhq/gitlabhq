# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

require_relative '../../support/helpers/gitlab_ci'

RSpec.describe Support::GitlabCi, feature_category: :tooling do # rubocop:disable RSpec/SpecFilePathFormat -- Avoid deep nesting
  using RSpec::Parameterized::TableSyntax

  describe '.predictive_job?' do
    before do
      stub_env('CI_JOB_NAME', name)
    end

    subject { described_class.predictive_job? }

    where(:name, :expected) do
      'rspec-ee unit predictive 4/4' | be_truthy
      'rspec system predictive 1/4'  | be_truthy
      'rspec unit 1/4'               | be_falsey
      nil                            | be_falsey
    end

    with_them do
      it { is_expected.to expected }
    end
  end

  describe '.fail_fast_job?' do
    before do
      stub_env('CI_JOB_NAME', name)
    end

    subject { described_class.fail_fast_job? }

    where(:name, :expected) do
      'rspec fail-fast'              | be_truthy
      'rspec-ee fail-fast'           | be_truthy
      'rspec-ee unit predictive 4/4' | be_falsey
      nil                            | be_falsey
    end

    with_them do
      it { is_expected.to expected }
    end
  end
end
