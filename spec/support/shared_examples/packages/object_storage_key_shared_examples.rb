# frozen_string_literal: true

RSpec.shared_examples 'object_storage_key callbacks' do
  context 'when the record is created' do
    it 'sets object_storage_key' do
      model.save!

      expect(model.object_storage_key).to eq(expected_object_storage_key.to_s)
    end

    context 'when using `update!`' do
      let(:metadata_content) { {}.to_json }

      it 'sets object_storage_key' do
        model.update!(
          file: CarrierWaveStringFile.new(metadata_content),
          size: metadata_content.bytesize
        )

        expect(model.object_storage_key).to eq(expected_object_storage_key.to_s)
      end
    end
  end

  context 'when the record is updated' do
    it 'does not update object_storage_key' do
      model.save!
      existing_object_storage_key = model.object_storage_key

      model.touch

      expect(model.object_storage_key).to eq(existing_object_storage_key.to_s)
    end

    context 'when an attribute the key is derived from changes' do
      it 'does not recompute object_storage_key' do
        model.save!
        model.assign_attributes(key_source_attributes)

        expect { model.valid? }.not_to change { model.object_storage_key }
      end
    end
  end
end

RSpec.shared_examples 'object_storage_key readonly attributes' do
  it 'sets object_storage_key' do
    expect(model.object_storage_key).to be_present
  end

  context 'when the record is persisted' do
    let(:new_object_storage_key) { 'object/storage/updated_key' }
    let(:metadata_content) { {}.to_json }

    it 'does not re-set object_storage_key' do
      model.update!(
        object_storage_key: new_object_storage_key,
        file: CarrierWaveStringFile.new(metadata_content),
        size: metadata_content.bytesize
      )

      expect(model.reload.object_storage_key).not_to eq(new_object_storage_key)
    end
  end
end
