# frozen_string_literal: true

RSpec.shared_examples 'cells claimable model' do |subject_type:, subject_key:, source_type:, claiming_attributes:|
  it 'has the expected subject_type' do
    expect(described_class.cells_claims_subject_type).to eq(subject_type)
  end

  it 'has the expected subject_key' do
    expect(described_class.cells_claims_subject_key).to eq(subject_key)
  end

  it 'has the expected source_type' do
    expect(described_class.cells_claims_source_type).to eq(source_type)
  end

  it 'has the expected unique attributes' do
    claiming_attributes.each do |attr_name|
      expect(described_class.cells_claims_attributes).to have_key(attr_name)
    end
  end
end
