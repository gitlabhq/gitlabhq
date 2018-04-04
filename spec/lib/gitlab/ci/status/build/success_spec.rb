require 'spec_helper'

describe Gitlab::Ci::Status::Build::Success do
  let(:user) { create(:user) }

  subject do
    described_class.new(double('subject'))
  end

  describe '#illustration' do
    it { expect(subject.illustration).to include(:image, :size, :title) }
  end

  describe '.matches?' do
    subject {described_class.matches?(build, user) }

    context 'when build succeeded' do
      let(:build) { create(:ci_build, :success) }

      it 'is a correct match' do
        expect(subject).to be true
      end
    end

    context 'when build did not succeed' do
      let(:build) { create(:ci_build, :skipped) }

      it 'does not match' do
        expect(subject).to be false
      end
    end
  end
end
