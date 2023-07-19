# frozen_string_literal: true
require 'fast_spec_helper'
require 'rspec-parameterized'
require 'gitlab/rspec/all'

RSpec.describe Gitlab::Metrics::Environment, feature_category: :error_budgets do
  include StubENV

  describe '.web? .api? .git?' do
    using RSpec::Parameterized::TableSyntax

    where(:env_var, :git, :api, :web) do
      'web'        | false | false | true
      'api'        | false | true  | false
      'git'        | true  | false | false
      'websockets' | false | false | false
      nil          | true  | true  | true
      ''           | true  | true  | true
    end

    with_them do
      it 'each method returns as expected' do
        stub_env('GITLAB_METRICS_INITIALIZE', env_var)

        expect(described_class.git?).to eq(git)
        expect(described_class.web?).to eq(web)
        expect(described_class.api?).to eq(api)
      end
    end
  end
end
