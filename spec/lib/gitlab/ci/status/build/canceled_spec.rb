# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Build::Canceled, feature_category: :continuous_integration do
  let(:user) { build_stubbed(:user) }

  subject do
    described_class.new(double('subject'))
  end

  describe '#illustration' do
    it { expect(subject.illustration).to include(:image, :size, :title) }
  end

  describe '.matches?' do
    subject { described_class.matches?(build, user) }

    context 'when build is canceled' do
      let(:build) { build_stubbed(:ci_build, :canceled) }

      it 'is a correct match' do
        expect(subject).to be true
      end
    end

    context 'when build is not canceled' do
      let(:build) { build_stubbed(:ci_build) }

      it 'does not match' do
        expect(subject).to be false
      end
    end
  end
end
