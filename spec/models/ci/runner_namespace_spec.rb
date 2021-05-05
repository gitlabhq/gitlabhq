# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerNamespace do
  it_behaves_like 'includes Limitable concern' do
    subject { build(:ci_runner_namespace, group: create(:group, :nested), runner: create(:ci_runner, :group)) }
  end
end
