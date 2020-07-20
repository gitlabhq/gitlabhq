# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectDailyStatistic do
  it { is_expected.to belong_to(:project) }
end
