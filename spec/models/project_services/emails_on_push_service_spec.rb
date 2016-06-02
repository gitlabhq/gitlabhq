require 'spec_helper'

describe EmailsOnPushService do
  describe 'Validations' do
    context 'when service is active' do
      before { subject.active = true }

      it { is_expected.to validate_presence_of(:recipients) }
    end

    context 'when service is inactive' do
      before { subject.active = false }

      it { is_expected.not_to validate_presence_of(:recipients) }
    end
  end
end
