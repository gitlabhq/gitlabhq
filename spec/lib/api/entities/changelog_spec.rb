# frozen_string_literal: true

require 'fast_spec_helper'
require 'grape_entity'

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
