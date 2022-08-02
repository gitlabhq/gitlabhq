# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Build::Created do
  let(:user) { create(:user) }

  subject do
    described_class.new(double('subject'))
  end

  describe '#illustration' do
    it { expect(subject.illustration).to include(:image, :size, :title, :content) }
  end

  describe '.matches?' do
    subject { described_class.matches?(build, user) }

    context 'when build is created' do
      let(:build) { create(:ci_build, :created) }

      it 'is a correct match' do
        expect(subject).to be true
      end
    end

    context 'when build is not created' do
      let(:build) { create(:ci_build) }

      it 'does not match' do
        expect(subject).to be false
      end
    end
  end
end
