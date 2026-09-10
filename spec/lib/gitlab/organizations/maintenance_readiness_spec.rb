# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Organizations::MaintenanceReadiness, feature_category: :organization do
  let_it_be(:organization) { create(:organization) }

  subject(:readiness) { described_class.new(organization) }

  describe '#ready?' do
    it 'is false while the drain checks are not yet implemented (#602822)' do
      expect(readiness.ready?).to be(false)
    end
  end
end
