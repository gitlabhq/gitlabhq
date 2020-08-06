# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::Validator::CustomFormats do
  describe '#format_handlers' do
    describe 'add_to_metric_id_cache' do
      it 'adds data to metric id cache' do
        subject.format_handlers['add_to_metric_id_cache'].call('metric_id', '_schema')

        expect(subject.metric_ids_cache).to eq(["metric_id"])
      end
    end
  end
end
