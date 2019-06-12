# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespace::AggregationSchedule, type: :model do
  it { is_expected.to belong_to :namespace }
end
