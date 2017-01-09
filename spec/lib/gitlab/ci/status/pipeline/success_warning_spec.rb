require 'spec_helper'

describe Gitlab::Ci::Status::Pipeline::SuccessWarning do
  subject do
    described_class.new(double('status'))
  end

  describe '#test' do
    it { expect(subject.text).to eq 'passed' }
  end

  describe '#label' do
    it { expect(subject.label).to eq 'passed with warnings' }
  end

  describe '#icon' do
    it { expect(subject.icon).to eq 'icon_status_warning' }
  end

  describe '#group' do
    it { expect(subject.group).to eq 'success_with_warnings' }
  end

  describe '.matches?' do
    context 'when pipeline is successful' do
      let(:pipeline) do
        create(:ci_pipeline, status: :success)
      end

      context 'when pipeline has warnings' do
        before do
          allow(pipeline).to receive(:has_warnings?).and_return(true)
        end

        it 'is a correct match' do
          expect(described_class.matches?(pipeline, double)).to eq true
        end
      end

      context 'when pipeline does not have warnings' do
        it 'does not match' do
          expect(described_class.matches?(pipeline, double)).to eq false
        end
      end
    end

    context 'when pipeline is not successful' do
      let(:pipeline) do
        create(:ci_pipeline, status: :skipped)
      end

      context 'when pipeline has warnings' do
        before do
          allow(pipeline).to receive(:has_warnings?).and_return(true)
        end

        it 'does not match' do
          expect(described_class.matches?(pipeline, double)).to eq false
        end
      end

      context 'when pipeline does not have warnings' do
        it 'does not match' do
          expect(described_class.matches?(pipeline, double)).to eq false
        end
      end
    end
  end
end
