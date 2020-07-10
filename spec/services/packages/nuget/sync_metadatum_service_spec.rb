# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::SyncMetadatumService do
  let_it_be(:package, reload: true) { create(:nuget_package) }
  let_it_be(:metadata) do
    {
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

        metadata.each do |attribute, expected_value|
          expect(nuget_metadatum.send(attribute)).to eq(expected_value)
        end
      end
    end

    it 'creates a nuget metadatum' do
      expect { subject }
        .to change { package.nuget_metadatum.present? }.from(false).to(true)
    end

    it_behaves_like 'saving metadatum attributes'

    context 'with exisiting nuget metadatum' do
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
  end
end
