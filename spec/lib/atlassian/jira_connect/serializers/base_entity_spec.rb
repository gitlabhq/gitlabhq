# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::JiraConnect::Serializers::BaseEntity, feature_category: :integrations do
  let(:update_sequence_id) { nil }

  subject do
    described_class.represent(
      anything,
      update_sequence_id: update_sequence_id
    )
  end

  it 'generates the update_sequence_id' do
    allow(Atlassian::JiraConnect::Client).to receive(:generate_update_sequence_id).and_return(1)

    expect(subject.value_for(:updateSequenceId)).to eq(1)
  end

  context 'with update_sequence_id option' do
    let(:update_sequence_id) { 123 }

    it 'uses the custom update_sequence_id' do
      expect(subject.value_for(:updateSequenceId)).to eq(123)
    end
  end
end
