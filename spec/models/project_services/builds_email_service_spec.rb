require 'spec_helper'

describe BuildsEmailService do
  let(:data) { Gitlab::BuildDataBuilder.build(create(:ci_build)) }

  describe 'Validations' do
    context 'when service is active' do
      before { subject.active = true }

      it { is_expected.to validate_presence_of(:recipients) }

      context 'when pusher is added' do
        before { subject.add_pusher = true }

        it { is_expected.not_to validate_presence_of(:recipients) }
      end
    end

    context 'when service is inactive' do
      before { subject.active = false }

      it { is_expected.not_to validate_presence_of(:recipients) }
    end
  end

  describe '#execute' do
    it 'sends email' do
      subject.recipients = 'test@gitlab.com'
      data[:build_status] = 'failed'

      expect(BuildEmailWorker).to receive(:perform_async)

      subject.execute(data)
    end

    it 'does not send email with succeeded build and notify_only_broken_builds on' do
      expect(subject).to receive(:notify_only_broken_builds).and_return(true)
      data[:build_status] = 'success'

      expect(BuildEmailWorker).not_to receive(:perform_async)

      subject.execute(data)
    end

    it 'does not send email with failed build and build_allow_failure is true' do
      data[:build_status] = 'failed'
      data[:build_allow_failure] = true

      expect(BuildEmailWorker).not_to receive(:perform_async)

      subject.execute(data)
    end

    it 'does not send email with unknown build status' do
      data[:build_status] = 'foo'

      expect(BuildEmailWorker).not_to receive(:perform_async)

      subject.execute(data)
    end

    it 'does not send email when recipients list is empty' do
      subject.recipients = ' ,, '
      data[:build_status] = 'failed'

      expect(BuildEmailWorker).not_to receive(:perform_async)

      subject.execute(data)
    end
  end
end
