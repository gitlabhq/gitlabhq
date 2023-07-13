# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::SchemaInconsistenciesMetric, feature_category: :database do
  before do
    allow(Gitlab::Schema::Validation::Runner).to receive(:new).and_return(runner)
  end

  let(:runner) { instance_double(Gitlab::Schema::Validation::Runner, execute: inconsistencies) }
  let(:inconsistency_class) { Gitlab::Schema::Validation::Inconsistency }

  let(:inconsistencies) do
    [
      instance_double(inconsistency_class, object_name: 'index_name_1', type: 'wrong_indexes', object_type: 'index'),
      instance_double(inconsistency_class, object_name: 'index_name_2', type: 'missing_indexes',
        object_type: 'index'),
      instance_double(inconsistency_class, object_name: 'index_name_3', type: 'extra_indexes', object_type: 'index')
    ]
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'all' } do
    let(:expected_value) do
      [
        { inconsistency_type: 'wrong_indexes', object_name: 'index_name_1', object_type: 'index' },
        { inconsistency_type: 'missing_indexes', object_name: 'index_name_2', object_type: 'index' },
        { inconsistency_type: 'extra_indexes', object_name: 'index_name_3', object_type: 'index' }
      ]
    end
  end

  context 'when the max number of inconsistencies is exceeded' do
    before do
      stub_const('Gitlab::Usage::Metrics::Instrumentations::SchemaInconsistenciesMetric::MAX_INCONSISTENCIES', 1)
    end

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'all' } do
      let(:expected_value) do
        [{ inconsistency_type: 'wrong_indexes', object_name: 'index_name_1', object_type: 'index' }]
      end
    end
  end
end
