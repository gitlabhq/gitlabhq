# frozen_string_literal: true

shared_examples 'updated exposed field' do
  it 'creates another Evidence object' do
    model.send("#{updated_field}=", updated_value)

    expect(model.evidence_summary_keys).to include(updated_field)
    expect { model.save! }.to change(Evidence, :count).by(1)
    expect(updated_json_field).to eq(updated_value)
  end
end

shared_examples 'updated non-exposed field' do
  it 'does not create any Evidence object' do
    model.send("#{updated_field}=", updated_value)

    expect(model.evidence_summary_keys).not_to include(updated_field)
    expect { model.save! }.not_to change(Evidence, :count)
  end
end

shared_examples 'updated field on non-linked entity' do
  it 'does not create any Evidence object' do
    model.send("#{updated_field}=", updated_value)

    expect(model.evidence_summary_keys).to be_empty
    expect { model.save! }.not_to change(Evidence, :count)
  end
end
