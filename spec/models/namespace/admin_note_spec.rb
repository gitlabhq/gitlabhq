# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespace::AdminNote, type: :model do
  let!(:namespace) { create(:namespace) }

  describe 'associations' do
    it { is_expected.to belong_to :namespace }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:namespace) }
    it { is_expected.to validate_length_of(:note).is_at_most(1000) }
  end
end
