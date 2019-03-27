# frozen_string_literal: true

require 'spec_helper'

describe ProjectDailyStatistic do
  it { is_expected.to belong_to(:project) }
end
