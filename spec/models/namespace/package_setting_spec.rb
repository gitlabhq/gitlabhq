# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespace::PackageSetting, feature_category: :package_registry do
  describe 'relationships' do
    it { is_expected.to belong_to(:namespace) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:namespace) }

    describe '#maven_duplicates_allowed' do
      it { is_expected.to validate_length_of(:maven_duplicate_exception_regex).is_at_most(255) }
    end

    it { is_expected.not_to allow_value(nil).for(:nuget_symbol_server_enabled) }

    it { is_expected.to validate_length_of(:generic_duplicate_exception_regex).is_at_most(255) }
    it { is_expected.to validate_length_of(:nuget_duplicate_exception_regex).is_at_most(255) }

    it { is_expected.to allow_value(true, false).for(:terraform_module_duplicates_allowed) }
    it { is_expected.not_to allow_value(nil).for(:terraform_module_duplicates_allowed) }
    it { is_expected.to validate_length_of(:terraform_module_duplicate_exception_regex).is_at_most(255) }

    describe 'regex values' do
      let_it_be(:package_settings) { create(:namespace_package_setting) }

      subject { package_settings }

      valid_regexps = %w[SNAPSHOT .* v.+ v10.1.* (?:v.+|SNAPSHOT|TEMP)]
      invalid_regexps = ['[', '(?:v.+|SNAPSHOT|TEMP']

      %i[maven_duplicate_exception_regex generic_duplicate_exception_regex nuget_duplicate_exception_regex].each do |attribute|
        valid_regexps.each do |valid_regexp|
          it { is_expected.to allow_value(valid_regexp).for(attribute) }
        end

        invalid_regexps.each do |invalid_regexp|
          it { is_expected.not_to allow_value(invalid_regexp).for(attribute) }
        end
      end
    end
  end

  describe 'scopes' do
    describe '.namespace_id_in' do
      let_it_be(:package_settings) { create(:namespace_package_setting) }
      let_it_be(:other_package_settings) { create(:namespace_package_setting) }

      subject { described_class.namespace_id_in([package_settings.namespace_id]) }

      it { is_expected.to eq([package_settings]) }
    end

    describe '.with_terraform_module_duplicates_allowed_or_exception_regex' do
      let_it_be(:package_settings) { create(:namespace_package_setting) }

      subject { described_class.with_terraform_module_duplicates_allowed_or_exception_regex }

      context 'when terraform_module_duplicates_allowed is true' do
        before do
          package_settings.update_column(:terraform_module_duplicates_allowed, true)
        end

        it { is_expected.to eq([package_settings]) }
      end

      context 'when terraform_module_duplicate_exception_regex is present' do
        before do
          package_settings.update_column(:terraform_module_duplicate_exception_regex, 'foo')
        end

        it { is_expected.to eq([package_settings]) }
      end

      context 'when terraform_module_duplicates_allowed is false and terraform_module_duplicate_exception_regex is empty' do
        before do
          package_settings.update_columns(
            terraform_module_duplicates_allowed: false,
            terraform_module_duplicate_exception_regex: ''
          )
        end

        it { is_expected.to be_empty }
      end
    end
  end

  shared_examples 'package types without package_settings' do
    package_types = Packages::Package.package_types.keys - Namespace::PackageSetting::PACKAGES_WITH_SETTINGS
    package_types.each do |package_type|
      context "with package_type:#{package_type}" do
        let_it_be(:package) { create("#{package_type}_package", package_name_and_version(package_type)) }
        let_it_be(:package_settings) { package.project.namespace.package_settings }

        it 'raises an error' do
          expect { subject }.to raise_error(Namespace::PackageSetting::PackageSettingNotImplemented)
        end
      end
    end
  end

  describe '.duplicates_allowed?' do
    using RSpec::Parameterized::TableSyntax

    subject { described_class.duplicates_allowed?(package) }

    context 'package types with package_settings' do
      Namespace::PackageSetting::PACKAGES_WITH_SETTINGS.each do |package_type|
        context "with package_type: #{package_type}" do
          let_it_be(:package) { create("#{package_type}_package", package_name_and_version(package_type)) }
          let(:package_name) { package.name }
          let(:package_version) { package.version }
          let_it_be(:package_type) { package.package_type }
          let_it_be(:package_setting) { package.project.namespace.package_settings }

          where(:duplicates_allowed, :duplicate_exception_regex, :result) do
            true  | ref(:package_name)    | false
            true  | ref(:package_version) | false
            true  | 'asdf'                | true
            true  | '.*'                  | false
            true  | '.*be.*'              | false
            false | ref(:package_name)    | true
            false | ref(:package_version) | true
            false | 'asdf'                | false
            false | '.*'                  | true
            false | '.*be.*'              | true
          end

          with_them do
            before do
              package_setting.update!(
                "#{package_type}_duplicates_allowed" => duplicates_allowed,
                "#{package_type}_duplicate_exception_regex" => duplicate_exception_regex
              )
            end

            it { is_expected.to be(result) }
          end
        end
      end
    end

    it_behaves_like 'package types without package_settings'
  end

  describe 'package forwarding attributes' do
    %i[maven_package_requests_forwarding pypi_package_requests_forwarding npm_package_requests_forwarding]
      .each do |attribute|
        it_behaves_like 'a cascading namespace setting boolean attribute',
          settings_attribute_name: attribute,
          settings_association: :package_settings
      end
  end

  def package_name_and_version(package_type)
    package_name = 'foo'
    version = '1.0.0-beta'

    package_name = 'foo/bar' if package_type == 'terraform_module'
    version = 'v1.0.1' if package_type == 'golang'

    { name: package_name, version: version }
  end
end
