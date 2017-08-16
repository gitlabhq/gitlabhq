require 'spec_helper'

describe Ci::Group do
  subject do
    described_class.new('test', name: 'rspec', jobs: jobs)
  end

  let!(:jobs) { build_list(:ci_build, 1, :success) }

  it { is_expected.to include_module(StaticModel) }

  it { is_expected.to respond_to(:stage) }
  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:jobs) }
  it { is_expected.to respond_to(:status) }

  describe '#size' do
    it 'returns the number of statuses in the group' do
      expect(subject.size).to eq(1)
    end
  end

  describe '#detailed_status' do
    context 'when there is only one item in the group' do
      it 'calls the status from the object itself' do
        expect(jobs.first).to receive(:detailed_status)

        expect(subject.detailed_status(double(:user)))
      end
    end

    context 'when there are more than one commit status in the group' do
      let(:jobs) do
        [create(:ci_build, :failed),
         create(:ci_build, :success)]
      end

      it 'fabricates a new detailed status object' do
        expect(subject.detailed_status(double(:user)))
          .to be_a(Gitlab::Ci::Status::Failed)
      end
    end
  end
end
