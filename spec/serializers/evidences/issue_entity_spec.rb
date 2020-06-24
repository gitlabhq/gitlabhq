# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Evidences::IssueEntity do
  let(:entity) { described_class.new(build(:issue)) }

  subject { entity.as_json }

  it 'exposes the expected fields' do
    expect(subject.keys).to contain_exactly(:id, :title, :description, :state, :iid, :confidential, :created_at, :due_date)
  end
end
