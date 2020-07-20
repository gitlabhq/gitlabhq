# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectSetting, type: :model do
  it { is_expected.to belong_to(:project) }
end
