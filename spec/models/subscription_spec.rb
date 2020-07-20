# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Subscription do
  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:subscribable) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:subscribable) }
    it { is_expected.to validate_presence_of(:user) }

    it 'validates uniqueness of project_id scoped to subscribable_id, subscribable_type, and user_id' do
      create(:subscription)

      expect(subject).to validate_uniqueness_of(:project_id).scoped_to([:subscribable_id, :subscribable_type, :user_id])
    end
  end
end
