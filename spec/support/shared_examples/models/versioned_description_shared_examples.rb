# frozen_string_literal: true

RSpec.shared_examples 'versioned description' do
  describe 'associations' do
    it { is_expected.to have_many(:description_versions) }
  end

  describe 'save_description_version' do
    let(:factory_name) { described_class.name.underscore.to_sym }
    let!(:model) { create(factory_name, description: 'Original description') }

    context 'when description was changed' do
      before do
        model.update!(description: 'New description')
      end

      it 'saves the old and new description for the first update' do
        expect(model.description_versions.first.description).to eq('Original description')
        expect(model.description_versions.last.description).to eq('New description')
      end

      it 'only saves the new description for subsequent updates' do
        expect { model.update!(description: 'Another description') }.to change { model.description_versions.count }.by(1)

        expect(model.description_versions.last.description).to eq('Another description')
      end

      it 'sets the new description version to `saved_description_version`' do
        expect(model.saved_description_version).to eq(model.description_versions.last)
      end

      it 'clears `saved_description_version` after another save that does not change description' do
        model.save!

        expect(model.saved_description_version).to be_nil
      end
    end

    context 'when description was not changed' do
      it 'does not save any description version' do
        expect { model.save! }.not_to change { model.description_versions.count }

        expect(model.saved_description_version).to be_nil
      end
    end
  end
end
