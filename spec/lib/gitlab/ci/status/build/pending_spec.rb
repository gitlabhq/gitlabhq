# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Build::Pending, feature_category: :continuous_integration do
  let_it_be(:user, freeze: true) { create(:user) }

  let(:core_status) { instance_double(Gitlab::Ci::Status::Core) }

  subject(:status) { described_class.new(core_status) }

  describe '#illustration' do
    it { expect(status.illustration).to include(:image, :size, :title, :content) }
  end

  describe '.matches?' do
    subject(:matches?) { described_class.matches?(build, user) }

    context 'when build is pending' do
      let(:build) { create(:ci_build, :pending) }

      it 'is a correct match' do
        is_expected.to be true
      end
    end

    context 'when build is not pending' do
      let(:build) { create(:ci_build, :success) }

      it 'does not match' do
        is_expected.to be false
      end
    end
  end
end
