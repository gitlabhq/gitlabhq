require 'spec_helper'

describe Gitlab::Ci::Status::Factory do
  subject do
    described_class.new(resource, user)
  end

  let(:user) { create(:user) }

  let(:status) { subject.fabricate! }

  context 'when object has a core status' do
    HasStatus::AVAILABLE_STATUSES.each do |core_status|
      context "when core status is #{core_status}" do
        let(:resource) { double(status: core_status) }

        it "fabricates a core status #{core_status}" do
          expect(status).to be_a(
            Gitlab::Ci::Status.const_get(core_status.capitalize))
        end
      end
    end
  end
end
