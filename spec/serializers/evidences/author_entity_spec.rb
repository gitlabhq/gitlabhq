# frozen_string_literal: true

require 'spec_helper'

describe Evidences::AuthorEntity do
  let(:entity) { described_class.new(build(:author)) }

  subject { entity.as_json }

  it 'exposes the expected fields' do
    expect(subject.keys).to contain_exactly(:id, :name, :email)
  end
end
