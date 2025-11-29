# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Build::Created, feature_category: :continuous_integration do
  let(:user) { build_stubbed(:user) }
  let(:core_status) { instance_double(Gitlab::Ci::Status::Core) }

  subject(:status) { described_class.new(core_status) }

  describe '#illustration' do
    it { expect(status.illustration).to include(:image, :size, :title, :content) }
  end

  describe '.matches?' do
    subject(:matches?) { described_class.matches?(build, user) }

    context 'when build is created' do
      let(:build) { build_stubbed(:ci_build, :created) }

      it 'is a correct match' do
        is_expected.to be true
      end
    end

    context 'when build is not created' do
      let(:build) { build_stubbed(:ci_build) }

      it 'does not match' do
        is_expected.to be false
      end
    end
  end
end
