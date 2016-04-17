require 'spec_helper'

describe BuildsEmailService do
  let(:build) { create(:ci_build) }
  let(:data) { Gitlab::BuildDataBuilder.build(build) }
  let!(:project) { create(:project, :public, ci_id: 1) }
  let(:service) { described_class.new(project: project, active: true) }

  describe '#execute' do
    it 'sends email' do
      service.recipients = 'test@gitlab.com'
      data[:build_status] = 'failed'
      expect(BuildEmailWorker).to receive(:perform_async)
      service.execute(data)
    end

    it 'does not send email with succeeded build and notify_only_broken_builds on' do
      expect(service).to receive(:notify_only_broken_builds).and_return(true)
      data[:build_status] = 'success'
      expect(BuildEmailWorker).not_to receive(:perform_async)
      service.execute(data)
    end

    it 'does not send email with failed build and build_allow_failure is true' do
      data[:build_status] = 'failed'
      data[:build_allow_failure] = true
      expect(BuildEmailWorker).not_to receive(:perform_async)
      service.execute(data)
    end

    it 'does not send email with unknown build status' do
      data[:build_status] = 'foo'
      expect(BuildEmailWorker).not_to receive(:perform_async)
      service.execute(data)
    end

    it 'does not send email when recipients list is empty' do
      service.recipients = ' ,, '
      data[:build_status] = 'failed'
      expect(BuildEmailWorker).not_to receive(:perform_async)
      service.execute(data)
    end
  end

  describe 'validations' do

    context 'when pusher is not added' do
      before { service.add_pusher = false }

      it 'does not allow empty recipient input' do
        service.recipients = ''
        expect(service.valid?).to be false
      end

      it 'does allow non-empty recipient input' do
        service.recipients = 'test@example.com'
        expect(service.valid?).to be true
      end

    end

    context 'when pusher is added' do
      before { service.add_pusher = true }

      it 'does allow empty recipient input' do
        service.recipients = ''
        expect(service.valid?).to be true
      end

      it 'does allow non-empty recipient input' do
        service.recipients = 'test@example.com'
        expect(service.valid?).to be true
      end
    end
  end
end
