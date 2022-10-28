# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DependencyProxy::GroupSetting, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:group) }
  end

  describe 'default values' do
    it { is_expected.to be_enabled }
    it { expect(described_class.new(enabled: false)).not_to be_enabled }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:group) }
  end
end
