# frozen_string_literal: true

RSpec.shared_examples 'manual playable stage' do |stage_type|
  let(:stage) { build(stage_type, status: status) }

  describe '#manual_playable?' do
    subject { stage.manual_playable? }

    context 'when is manual' do
      let(:status) { 'manual' }

      it { is_expected.to be_truthy }
    end

    context 'when is scheduled' do
      let(:status) { 'scheduled' }

      it { is_expected.to be_truthy }
    end

    context 'when is skipped' do
      let(:status) { 'skipped' }

      it { is_expected.to be_truthy }
    end
  end
end
