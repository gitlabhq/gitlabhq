# frozen_string_literal: true

require "spec_helper"

RSpec.describe ::Applications::CreateService do
  include TestRequestHelpers

  let(:user) { create(:user) }
  let(:params) { attributes_for(:application) }

  subject { described_class.new(user, params) }

  it { expect { subject.execute(test_request) }.to change { Doorkeeper::Application.count }.by(1) }
end
