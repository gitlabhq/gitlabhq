# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EmailRejectionMailer do
  include EmailSpec::Matchers

  describe '#rejection' do
    let(:raw_email) { 'From: someone@example.com\nraw email here' }

    subject { described_class.rejection('some rejection reason', raw_email) }

    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'
  end
end
