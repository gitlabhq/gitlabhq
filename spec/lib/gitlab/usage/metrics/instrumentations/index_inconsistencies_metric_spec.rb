# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::IndexInconsistenciesMetric, feature_category: :database do
  let(:runner) { instance_double(Gitlab::Schema::Validation::Runner, execute: inconsistencies) }
  let(:inconsistency_class) { Gitlab::Schema::Validation::Inconsistency }

  let(:inconsistencies) do
    [
      instance_double(inconsistency_class, object_name: 'index_name_1', type: 'wrong_indexes'),
      instance_double(inconsistency_class, object_name: 'index_name_2', type: 'missing_indexes'),
      instance_double(inconsistency_class, object_name: 'index_name_3', type: 'extra_indexes')
    ]
  end

  before do
    allow(Gitlab::Schema::Validation::Runner).to receive(:new).and_return(runner)
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'all' } do
    let(:expected_value) do
      [
        { inconsistency_type: 'wrong_indexes', object_name: 'index_name_1' },
        { inconsistency_type: 'missing_indexes', object_name: 'index_name_2' },
        { inconsistency_type: 'extra_indexes', object_name: 'index_name_3' }
      ]
    end
  end

  it 'runs the validation with replica fallback for ambiguous queries' do
    Gitlab::Database::LoadBalancing::SessionMap.clear_session
    session = Gitlab::Database::LoadBalancing::SessionMap.current(ApplicationRecord.load_balancer)

    expect(runner).to receive(:execute) do
      expect(session.fallback_to_replicas_for_ambiguous_queries?).to be(true)

      inconsistencies
    end

    described_class.new(time_frame: 'all').value
  end
end
