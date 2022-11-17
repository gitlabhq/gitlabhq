# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SlashCommands::Presenters::IncidentManagement::IncidentNew do
  subject { described_class.new }

  it 'returns the ephemeral message' do
    message = subject.present('It works!')

    expect(message).to be_a(Hash)
    expect(message[:text]).to eq('It works!')
    expect(message[:response_type]).to be(:ephemeral)
  end
end
