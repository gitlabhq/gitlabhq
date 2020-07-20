# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Evidences::ProjectEntity do
  let(:entity) { described_class.new(build(:project)) }

  subject { entity.as_json }

  it 'exposes the expected fields' do
    expect(subject.keys).to contain_exactly(:id, :name, :description, :created_at)
  end
end
