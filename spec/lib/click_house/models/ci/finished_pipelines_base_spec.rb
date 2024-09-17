# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Models::Ci::FinishedPipelinesBase, feature_category: :fleet_visibility do
  describe '.table_name' do
    it { expect { described_class.table_name }.to raise_error(NotImplementedError) }
  end
end
