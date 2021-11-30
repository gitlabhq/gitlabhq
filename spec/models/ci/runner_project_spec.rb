# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerProject do
  it_behaves_like 'includes Limitable concern' do
    subject { build(:ci_runner_project, project: create(:project), runner: create(:ci_runner, :project)) }
  end
end
