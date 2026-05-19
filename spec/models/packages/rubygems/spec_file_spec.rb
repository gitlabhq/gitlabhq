# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Rubygems::SpecFile, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }

  it { is_expected.to be_a FileStoreMounter }

  it_behaves_like 'destructible', factory: :rubygems_spec_file

  describe 'loose foreign keys' do
    it_behaves_like 'update by a loose foreign key' do
      let_it_be(:model) { create(:rubygems_spec_file, status: :default) }

      let!(:parent) { model.project }
    end
  end

  describe 'relationships' do
    it { is_expected.to belong_to(:project).inverse_of(:rubygems_spec_files) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:file) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:size) }
    it { is_expected.to validate_presence_of(:file_name) }
    it { is_expected.to validate_presence_of(:object_storage_key) }

    describe 'uniqueness' do
      let_it_be(:spec_file) { create(:rubygems_spec_file, project: project) }

      it 'ensures the file_name is unique with the given project' do
        expect do
          create(:rubygems_spec_file, project: project)
        end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: File name has already been taken')
      end

      it 'allows duplicate file_name in different projects' do
        expect do
          create(:rubygems_spec_file, project: create(:project))
        end.not_to raise_error
      end
    end
  end

  describe '#object_storage_key' do
    it_behaves_like 'object_storage_key callbacks' do
      let(:model) { build(:rubygems_spec_file, project: project) }
      let(:expected_object_storage_key) do
        Gitlab::HashedPath.new(
          'packages', 'rubygems', 'spec_files', OpenSSL::Digest::SHA256.hexdigest(model.file_name),
          root_hash: project.id
        )
      end
    end

    describe 'readonly object_storage_key' do
      let_it_be(:model) { create(:rubygems_spec_file, project: project) }

      it 'sets object_storage_key' do
        expect(model.object_storage_key).to be_present
      end

      it 'does not persist a re-assignment' do
        model.object_storage_key = 'object/storage/updated_key'
        model.save!

        expect(model.reload.object_storage_key).not_to eq('object/storage/updated_key')
      end
    end
  end
end
