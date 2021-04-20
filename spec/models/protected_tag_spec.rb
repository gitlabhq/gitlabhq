# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedTag do
  describe 'Associations' do
    it { is_expected.to belong_to(:project).touch(true) }
  end

  describe 'Validation' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:name) }
  end
end
