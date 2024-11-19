# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Access, feature_category: :permissions do
  let_it_be(:member) { create(:group_member, :developer) }

  describe '#role_description' do
    it 'returns the correct description of the access role' do
      role = described_class.option_descriptions[described_class::DEVELOPER]

      expect(member.role_description).to eq(role)
    end
  end
end
