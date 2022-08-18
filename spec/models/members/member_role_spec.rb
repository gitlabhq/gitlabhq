# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MemberRole do
  describe 'associations' do
    it { is_expected.to belong_to(:namespace) }
    it { is_expected.to have_many(:members) }
  end

  describe 'validation' do
    subject { described_class.new }

    it { is_expected.to validate_presence_of(:namespace_id) }
    it { is_expected.to validate_presence_of(:base_access_level) }
  end
end
