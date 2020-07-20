# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebIdeTerminalSerializer do
  let(:build) { create(:ci_build) }

  subject { described_class.new.represent(WebIdeTerminal.new(build)) }

  it 'represents WebIdeTerminalEntity entities' do
    expect(described_class.entity_class).to eq(WebIdeTerminalEntity)
  end

  it 'accepts WebIdeTerminal as a resource' do
    expect(subject[:id]).to eq build.id
  end

  context 'when resource is a build' do
    subject { described_class.new.represent(build) }

    it 'transforms it into a WebIdeTerminal resource' do
      expect(WebIdeTerminal).to receive(:new)

      subject
    end
  end
end
