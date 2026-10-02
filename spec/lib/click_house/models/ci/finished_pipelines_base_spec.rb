# frozen_string_literal: true

require 'fast_spec_helper'
require 'click_house/client'

RSpec.describe ClickHouse::Models::Ci::FinishedPipelinesBase, feature_category: :fleet_visibility do
  describe '.table_name' do
    it { expect { described_class.table_name }.to raise_error(NotImplementedError) }
  end
end
