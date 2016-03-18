require 'spec_helper'

describe BuildsEmailService do
  let(:build) { create(:ci_build) }
  let(:data) { Gitlab::BuildDataBuilder.build(build) }
  let(:service) { BuildsEmailService.new }

  describe :execute do
    it "sends email" do
      service.recipients = 'test@gitlab.com'
      data[:build_status] = 'failed'
      expect(BuildEmailWorker).to receive(:perform_async)
      service.execute(data)
    end

    it "does not sends email with failed build and allowed_failure on" do
      data[:build_status] = 'failed'
      data[:build_allow_failure] = true
      expect(BuildEmailWorker).not_to receive(:perform_async)
      service.execute(data)
    end
  end
end
