# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::SuccessWarning, feature_category: :continuous_integration do
  let(:status) { double('status') }

  subject do
    described_class.new(status)
  end

  describe '#text' do
    it { expect(subject.text).to eq 'Warning' }
  end

  describe '#label' do
    it { expect(subject.label).to eq 'passed with warnings' }
  end

  describe '#icon' do
    it { expect(subject.icon).to eq 'status_warning' }
  end

  describe '#group' do
    it { expect(subject.group).to eq 'success-with-warnings' }
  end

  describe '#name' do
    it { expect(subject.name).to eq 'SUCCESS_WITH_WARNINGS' }
  end

  describe '.matches?' do
    let(:matchable) { double('matchable') }

    context 'when matchable subject is successful' do
      before do
        allow(matchable).to receive(:success?).and_return(true)
      end

      context 'when matchable subject has warnings' do
        before do
          allow(matchable).to receive(:has_warnings?).and_return(true)
        end

        it 'is a correct match' do
          expect(described_class.matches?(matchable, double)).to eq true
        end
      end

      context 'when matchable subject does not have warnings' do
        before do
          allow(matchable).to receive(:has_warnings?).and_return(false)
        end

        it 'does not match' do
          expect(described_class.matches?(matchable, double)).to eq false
        end
      end
    end

    context 'when matchable subject is not successful' do
      before do
        allow(matchable).to receive(:success?).and_return(false)
      end

      context 'when matchable subject has warnings' do
        before do
          allow(matchable).to receive(:has_warnings?).and_return(true)
        end

        it 'does not match' do
          expect(described_class.matches?(matchable, double)).to eq false
        end
      end

      context 'when matchable subject does not have warnings' do
        it 'does not match' do
          expect(described_class.matches?(matchable, double)).to eq false
        end
      end
    end
  end
end
