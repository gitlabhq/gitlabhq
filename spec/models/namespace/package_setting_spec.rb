# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespace::PackageSetting, feature_category: :package_registry do
  describe 'relationships' do
    it { is_expected.to belong_to(:namespace) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:namespace) }

    describe '#maven_duplicates_allowed' do
      it { is_expected.to validate_inclusion_of(:maven_duplicates_allowed).in_array([true, false]) }
      it { is_expected.to validate_length_of(:maven_duplicate_exception_regex).is_at_most(255) }
    end

    it { is_expected.to allow_value(true, false).for(:nuget_symbol_server_enabled) }
    it { is_expected.not_to allow_value(nil).for(:nuget_symbol_server_enabled) }

    it { is_expected.to validate_inclusion_of(:generic_duplicates_allowed).in_array([true, false]) }
    it { is_expected.to validate_length_of(:generic_duplicate_exception_regex).is_at_most(255) }
    it { is_expected.to validate_inclusion_of(:nuget_duplicates_allowed).in_array([true, false]) }
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

  describe '#duplicates_allowed?' do
    using RSpec::Parameterized::TableSyntax

    subject { described_class.duplicates_allowed?(package) }

    context 'package types with package_settings' do
      # As more package types gain settings they will be added to this list
      [
        { format: :maven_package, package_name: 'foo' },
        { format: :generic_package, package_name: 'foo' },
        { format: :nuget_package, package_name: 'foo' },
        { format: :terraform_module_package, package_name: 'foo/bar' }
      ].each do |type|
        context "with package_type: #{type[:format]}" do
          let_it_be(:package) { create(type[:format], name: type[:package_name], version: '1.0.0-beta') }
          let_it_be(:package_type) { package.package_type }
          let_it_be(:package_setting) { package.project.namespace.package_settings }

          where(:duplicates_allowed, :duplicate_exception_regex, :result) do
            true  | ''       | true
            false | ''       | false
            false | '.*'     | true
            false | 'fo.*'   | true
            false | '.*be.*' | true
          end

          with_them do
            context "for #{type[:format]}" do
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
    end

    context 'package types without package_settings' do
      %i[npm_package conan_package pypi_package composer_package golang_package debian_package].each do |format|
        context "with package_type:#{format}" do
          let_it_be(:package) { create(format) } # rubocop:disable Rails/SaveBang
          let_it_be(:package_setting) { package.project.namespace.package_settings }

          it 'raises an error' do
            expect { subject }.to raise_error(Namespace::PackageSetting::PackageSettingNotImplemented)
          end
        end
      end
    end
  end

  describe 'package forwarding attributes' do
    %i[maven_package_requests_forwarding pypi_package_requests_forwarding npm_package_requests_forwarding]
      .each do |attribute|
        it_behaves_like 'a cascading namespace setting boolean attribute',
          settings_attribute_name: attribute,
          settings_association: :package_settings
      end
  end
end
