# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::FileMetadatum, type: :model do
  RSpec.shared_context 'Debian file metadatum' do |factory, trait|
    let_it_be_with_reload(:debian_package_file) { create(factory, trait) }
    let(:debian_file_metadatum) { debian_package_file.debian_file_metadatum }

    subject { debian_file_metadatum }
  end

  RSpec.shared_examples 'Test Debian file metadatum' do |has_component, has_architecture, has_fields, has_outdated|
    describe 'relationships' do
      it { is_expected.to belong_to(:package_file) }
    end

    describe 'validations' do
      describe '#package_file' do
        it { is_expected.to validate_presence_of(:package_file) }
      end

      describe '#file_type' do
        it { is_expected.to validate_presence_of(:file_type) }
      end

      describe '#component' do
        it "has_component=#{has_component}" do
          if has_component
            is_expected.to validate_presence_of(:component)
            is_expected.to allow_value('main').for(:component)
            is_expected.not_to allow_value('hé').for(:component)
          else
            is_expected.to validate_absence_of(:component)
          end
        end
      end

      describe '#architecture' do
        it "has_architecture=#{has_architecture}" do
          if has_architecture
            is_expected.to validate_presence_of(:architecture)
            is_expected.to allow_value('amd64').for(:architecture)
            is_expected.not_to allow_value('-a').for(:architecture)
          else
            is_expected.to validate_absence_of(:architecture)
          end
        end
      end

      describe '#fields' do
        if has_fields
          it { is_expected.to validate_presence_of(:fields) }
          it { is_expected.to allow_value({ 'a': 'b' }).for(:fields) }
          it { is_expected.not_to allow_value({ 'a': { 'b': 'c' } }).for(:fields) }
        else
          it { is_expected.to validate_absence_of(:fields) }
        end
      end

      describe '#debian_package_type' do
        before do
          debian_package_file.package.package_type = :pypi
        end

        it 'validates package of type debian' do
          expect(debian_file_metadatum).not_to be_valid
          expect(debian_file_metadatum.errors.to_a).to contain_exactly('Package file Package type must be Debian')
        end
      end
    end
  end

  using RSpec::Parameterized::TableSyntax

  where(:factory, :trait, :has_component, :has_architecture, :has_fields) do
    :debian_package_file      | :unknown   | false | false | false
    :debian_package_file      | :source    | true  | false | false
    :debian_package_file      | :dsc       | true  | false | true
    :debian_package_file      | :deb       | true  | true  | true
    :debian_package_file      | :udeb      | true  | true  | true
    :debian_package_file      | :buildinfo | true  | false | true
    :debian_package_file      | :changes   | false | false | true
  end

  with_them do
    include_context 'Debian file metadatum', params[:factory], params[:trait] do
      it_behaves_like 'Test Debian file metadatum', params[:has_component], params[:has_architecture], params[:has_fields], params[:has_outdated]
    end
  end
end
