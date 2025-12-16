# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Build::Skipped, feature_category: :continuous_integration do
  let(:core_status) { instance_double(Gitlab::Ci::Status::Core) }

  subject(:status) { described_class.new(core_status) }

  describe '#illustration' do
    it { expect(status.illustration).to include(:image, :size, :title) }
  end

  describe '.matches?' do
    let(:user) { build_stubbed(:user) }

    subject(:matches?) { described_class.matches?(build, user) }

    context 'when build is skipped' do
      let(:build) { build_stubbed(:ci_build, :skipped) }

      it 'is a correct match' do
        is_expected.to be true
      end
    end

    context 'when build is not skipped' do
      let(:build) { build_stubbed(:ci_build) }

      it 'does not match' do
        is_expected.to be false
      end
    end
  end
end
