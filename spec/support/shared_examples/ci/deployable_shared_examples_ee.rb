# frozen_string_literal: true

RSpec.shared_examples 'a deployable job in EE' do
  describe 'when the job is waiting for deployment approval' do
    let(:job) { create(factory_type, :manual, environment: 'production', pipeline: pipeline) }
    let!(:deployment) { create(:deployment, :blocked, deployable: job) }

    before do
      allow(deployment).to receive(:waiting_for_approval?).and_return(true)
    end

    it 'does not allow the job to be enqueued' do
      expect { job.enqueue! }.to raise_error(StateMachines::InvalidTransition)
    end
  end

  describe '#playable?' do
    context 'when job is waiting for deployment approval' do
      subject { build_stubbed(factory_type, :manual, environment: 'production', pipeline: pipeline) }

      let!(:deployment) { create(:deployment, :blocked, deployable: subject) }

      before do
        allow(deployment).to receive(:waiting_for_approval?).and_return(true)
      end

      it { is_expected.not_to be_playable }
    end
  end

  def factory_type
    described_class.name.underscore.tr('/', '_')
  end
end
