# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerNamespace do
  it_behaves_like 'includes Limitable concern' do
    subject { build(:ci_runner_namespace, group: create(:group, :nested), runner: create(:ci_runner, :group)) }
  end

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:model) { create(:ci_runner_namespace) }

    let!(:parent) { model.namespace }
  end
end
