# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UsersStarProject, type: :model do
  it { is_expected.to belong_to(:project).touch(false) }
end
