# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::SyncMetadatumService, feature_category: :package_registry do
  let_it_be(:package, reload: true) { create(:nuget_package) }
  let_it_be(:metadata) do
    {
      authors: 'Package authors',
      description: 'Package description',
      project_url: 'https://test.org/test',
      license_url: 'https://test.org/MIT',
      icon_url: 'https://test.org/icon.png'
    }
  end

  let(:service) { described_class.new(package, metadata) }
  let(:nuget_metadatum) { package.nuget_metadatum }

  describe '#execute' do
    subject { service.execute }

    RSpec.shared_examples 'saving metadatum attributes' do
      it 'saves nuget metadatum' do
        subject

        expect(nuget_metadatum).to have_attributes(**metadata)
      end
    end

    it 'creates a nuget metadatum' do
      expect { subject }
        .to change { package.nuget_metadatum.present? }.from(false).to(true)
    end

    it_behaves_like 'saving metadatum attributes'

    context 'with existing nuget metadatum' do
      let_it_be(:package) { create(:nuget_package, :with_metadatum) }

      it 'does not create a nuget metadatum' do
        expect { subject }.to change { ::Packages::Nuget::Metadatum.count }.by(0)
      end

      it_behaves_like 'saving metadatum attributes'

      context 'with empty metadata' do
        let_it_be(:metadata) { {} }

        it 'destroys the nuget metadatum' do
          expect { subject }
            .to change { package.reload.nuget_metadatum.present? }.from(true).to(false)
        end
      end
    end

    context 'with metadata containing only authors and description' do
      let_it_be(:metadata) { { authors: 'Package authors 2', description: 'Package description 2' } }

      it 'updates the nuget metadatum' do
        subject

        expect(nuget_metadatum).to have_attributes(
          authors: 'Package authors 2',
          description: 'Package description 2'
        )
      end
    end

    context 'with too long metadata' do
      let(:metadata) { super().merge(authors: 'a' * 260, description: 'a' * 4010) }
      let(:max_authors_length) { ::Packages::Nuget::Metadatum::MAX_AUTHORS_LENGTH }
      let(:max_description_length) { ::Packages::Nuget::Metadatum::MAX_DESCRIPTION_LENGTH }

      it 'truncates authors and description to the maximum length and logs its info' do
        %i[authors description].each do |field|
          expect(Gitlab::AppLogger).to receive(:info).with(
            class: described_class.name,
            package_id: package.id,
            project_id: package.project_id,
            message: "#{field.capitalize} is too long (maximum is #{send("max_#{field}_length")} characters)",
            field => metadata[field]
          )
        end

        subject

        expect(nuget_metadatum.authors.size).to eq(max_authors_length)
        expect(nuget_metadatum.description.size).to eq(max_description_length)
      end
    end
  end
end
