# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Status::Pipeline::Delayed do
  let(:pipeline) { double('pipeline') }

  subject do
    described_class.new(pipeline)
  end

  describe '#text' do
    it 'overrides status text' do
      expect(subject.text).to eq 'delayed'
    end
  end

  describe '#label' do
    it 'overrides status label' do
      expect(subject.label).to eq 'waiting for delayed job'
    end
  end

  describe '.matches?' do
    let(:user) { double('user') }

    subject { described_class.matches?(pipeline, user) }

    context 'when pipeline is scheduled' do
      let(:pipeline) { create(:ci_pipeline, :scheduled) }

      it 'is a correct match' do
        expect(subject).to be true
      end
    end

    context 'when pipeline is not scheduled' do
      let(:pipeline) { create(:ci_pipeline, :success) }

      it 'does not match' do
        expect(subject).to be false
      end
    end
  end
end
