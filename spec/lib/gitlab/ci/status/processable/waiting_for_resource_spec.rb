# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Processable::WaitingForResource do
  let(:user) { create(:user) }

  subject do
    processable = create(:ci_build, :waiting_for_resource, :resource_group)
    described_class.new(Gitlab::Ci::Status::Core.new(processable, user))
  end

  describe '#illustration' do
    it { expect(subject.illustration).to include(:image, :size, :title) }
  end

  describe '.matches?' do
    subject {described_class.matches?(processable, user) }

    context 'when processable is waiting for resource' do
      let(:processable) { create(:ci_build, :waiting_for_resource) }

      it 'is a correct match' do
        expect(subject).to be true
      end
    end

    context 'when processable is not waiting for resource' do
      let(:processable) { create(:ci_build) }

      it 'does not match' do
        expect(subject).to be false
      end
    end
  end
end
