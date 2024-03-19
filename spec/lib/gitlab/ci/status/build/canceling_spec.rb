# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Build::Canceling, feature_category: :continuous_integration do
  let(:user) { build_stubbed(:user) }

  subject(:status_instance) do
    described_class.new(double)
  end

  describe '#illustration' do
    it { expect(status_instance.illustration).to include(:image, :size, :title) }
  end

  describe '.matches?' do
    subject(:matches?) { described_class.matches?(build, user) }

    context 'when build is canceled' do
      let(:build) { build_stubbed(:ci_build, :canceling) }

      it 'is a correct match' do
        expect(matches?).to be true
      end
    end

    context 'when build is not canceled' do
      let(:build) { build_stubbed(:ci_build) }

      it 'does not match' do
        expect(matches?).to be false
      end
    end
  end
end
