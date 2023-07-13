# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::IndexInconsistenciesMetric, feature_category: :database do
  it_behaves_like 'a correct instrumented metric value', { time_frame: 'all' } do
    let(:expected_value) do
      [
        { inconsistency_type: 'wrong_indexes', object_name: 'index_name_1' },
        { inconsistency_type: 'missing_indexes', object_name: 'index_name_2' },
        { inconsistency_type: 'extra_indexes', object_name: 'index_name_3' }
      ]
    end

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
  end
end
