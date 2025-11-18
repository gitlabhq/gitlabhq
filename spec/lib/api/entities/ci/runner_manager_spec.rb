# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Ci::RunnerManager, feature_category: :runner_core do
  let_it_be(:runner_manager) { create(:ci_runner_machine) }

  let(:entity) { described_class.new(runner_manager) }

  subject(:runner_manager_entity) { entity.presented.as_json }

  exposed_fields = %i[id version revision platform architecture]

  exposed_fields.each do |field|
    it "exposes runner manager #{field}" do
      expect(runner_manager_entity[field]).to eq(runner_manager.public_send(field))
    end
  end

  it "exposes runner manager system_id" do
    expect(runner_manager_entity[:system_id]).to eq(runner_manager.system_xid)
  end

  it_behaves_like 'job_execution_status field', :runner_manager
end
