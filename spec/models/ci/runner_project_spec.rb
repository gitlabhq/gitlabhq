# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerProject do
  it_behaves_like 'includes Limitable concern' do
    before do
      skip_default_enabled_yaml_check

      stub_feature_flags(ci_runner_limits_override: false)
    end

    subject { build(:ci_runner_project, project: create(:project), runner: create(:ci_runner, :project)) }
  end
end
