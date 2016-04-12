require 'spec_helper'

describe BuildsEmailService do
  let(:build) { create(:ci_build) }
  let(:data) { Gitlab::BuildDataBuilder.build(build) }
  let(:service) { BuildsEmailService.new }

  describe :execute do
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
end
