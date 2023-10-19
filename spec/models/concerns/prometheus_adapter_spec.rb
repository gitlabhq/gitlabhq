# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PrometheusAdapter, :use_clean_rails_memory_store_caching do
  include PrometheusHelpers
  include ReactiveCachingHelpers

  let_it_be(:project) { create(:project, :with_prometheus_integration) }
  let(:integration) { project.prometheus_integration }

  let(:described_class) do
    Class.new do
      include PrometheusAdapter
    end
  end

  describe '#build_query_args' do
    subject { integration.build_query_args(*args) }

    context 'when active record models are included' do
      let(:args) { [double(:environment, id: 12)] }

      it 'serializes by id' do
        is_expected.to eq [12]
      end
    end

    context 'when args are safe for serialization' do
      let(:args) { ['stringy arg', 5, 6.0, :symbolic_arg] }

      it 'does nothing' do
        is_expected.to eq args
      end
    end
  end
end
