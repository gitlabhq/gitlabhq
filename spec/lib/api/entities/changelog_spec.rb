# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Changelog do
  let(:changelog) { "This is a changelog" }

  subject { described_class.new(changelog).as_json }

  it 'exposes correct attributes' do
    expect(subject).to include(:notes)
  end

  it 'exposes correct notes' do
    expect(subject[:notes]).to eq(changelog)
  end
end
