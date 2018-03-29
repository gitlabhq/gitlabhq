require 'spec_helper'

describe Gitlab::Ci::Status::Build::Manual do
  let(:user) { create(:user) }

  subject do
    build = create(:ci_build, :manual)
    described_class.new(Gitlab::Ci::Status::Core.new(build, user))
  end

  describe '#illustration' do
    it { expect(subject.illustration).to include(:image, :size, :title, :content) }
  end

  describe '.matches?' do
    subject {described_class.matches?(build, user) }

    context 'when build is manual' do
      let(:build) { create(:ci_build, :manual) }

      it 'is a correct match' do
        expect(subject).to be true
      end
    end

    context 'when build is not manual' do
      let(:build) { create(:ci_build) }

      it 'does not match' do
        expect(subject).to be false
      end
    end
  end
end
