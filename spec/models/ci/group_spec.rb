require 'spec_helper'

describe Ci::Group, models: true do
  subject { described_class.new('test', name: 'rspec', jobs: jobs) }
  let(:jobs) { [] }

  describe 'expectations' do
    it { is_expected.to include_module(StaticModel) }

    it { is_expected.to respond_to(:stage) }
    it { is_expected.to respond_to(:name) }
    it { is_expected.to respond_to(:jobs) }
    it { is_expected.to respond_to(:status) }
  end

  describe '#size' do
    it 'returns the size of the statusses array' do
      expect(subject.size).to eq(0)
    end
  end

  describe '#detailed_status' do
    let(:job) { build(:ci_build, :success) }
    let(:jobs) { [job] }

    context 'when there is only one item in the group' do
      it 'calls the status from the object itself' do
        expect(job).to receive(:detailed_status)

        subject.detailed_status(nil)
      end
    end

    context 'when there are more than 1 commit statuses' do
      let(:job1) { build(:ci_build) }
      let(:jobs) { [job, job1] }

      it 'fabricates a new Ci::Status object' do
        expect(subject.detailed_status(nil)).to be_a(Gitlab::Ci::Status::Created)
      end
    end
  end
end
