# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SlashCommands::Presenters::Error do
  subject { described_class.new('Error').message }

  it { is_expected.to be_a(Hash) }

  it 'shows the error message' do
    expect(subject[:response_type]).to be(:ephemeral)
    expect(subject[:status]).to eq(200)
    expect(subject[:text]).to eq('Error')
  end
end
