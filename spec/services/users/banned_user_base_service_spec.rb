# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::BannedUserBaseService, feature_category: :user_management do
  let(:admin) { create(:admin) }
  let(:base_service) { described_class.new(admin) }

  describe '#initialize' do
    it 'sets the current_user instance value' do
      expect(base_service.instance_values["current_user"]).to eq(admin)
    end
  end
end
