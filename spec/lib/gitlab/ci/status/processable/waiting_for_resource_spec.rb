# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Processable::WaitingForResource, feature_category: :continuous_integration do
  let(:user) { create(:user) }
  let(:processable) { create(:ci_build, :waiting_for_resource, :resource_group) }

  subject { described_class.new(Gitlab::Ci::Status::Core.new(processable, user)) }

  it 'fabricates status with correct details' do
    expect(subject.has_action?).to eq false
  end

  context 'when resource is retained by a build' do
    before do
      processable.resource_group.assign_resource_to(create(:ci_build))
    end

    it 'fabricates status with correct details' do
      expect(subject.has_action?).to eq true
      expect(subject.action_path).to include 'jobs'
    end
  end

  describe '#illustration' do
    it { expect(subject.illustration).to include(:image, :size, :title) }
  end

  describe '.matches?' do
    subject { described_class.matches?(processable, user) }

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
