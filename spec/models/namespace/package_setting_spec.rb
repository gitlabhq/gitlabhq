# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespace::PackageSetting do
  describe 'relationships' do
    it { is_expected.to belong_to(:namespace) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:namespace) }

    describe '#maven_duplicates_allowed' do
      it { is_expected.to allow_value(true).for(:maven_duplicates_allowed) }
      it { is_expected.to allow_value(false).for(:maven_duplicates_allowed) }
      it { is_expected.not_to allow_value(nil).for(:maven_duplicates_allowed) }
    end

    describe '#maven_duplicate_exception_regex' do
      let_it_be(:package_settings) { create(:namespace_package_setting) }

      subject { package_settings }

      valid_regexps = %w[SNAPSHOT .* v.+ v10.1.* (?:v.+|SNAPSHOT|TEMP)]
      invalid_regexps = ['[', '(?:v.+|SNAPSHOT|TEMP']

      valid_regexps.each do |valid_regexp|
        it { is_expected.to allow_value(valid_regexp).for(:maven_duplicate_exception_regex) }
      end

      invalid_regexps.each do |invalid_regexp|
        it { is_expected.not_to allow_value(invalid_regexp).for(:maven_duplicate_exception_regex) }
      end
    end
  end

  describe '#duplicates_allowed?' do
    using RSpec::Parameterized::TableSyntax

    subject { described_class.duplicates_allowed?(package) }

    context 'package types with package_settings' do
      # As more package types gain settings they will be added to this list
      [:maven_package].each do |format|
        let_it_be(:package) { create(format) } # rubocop:disable Rails/SaveBang
        let_it_be(:package_type) { package.package_type }
        let_it_be(:package_setting) { package.project.namespace.package_settings }

        where(:duplicates_allowed, :duplicate_exception_regex, :result) do
          true  | ''   | true
          false | ''   | false
          false | '.*' | true
        end

        with_them do
          context "for #{format}" do
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

    context 'package types without package_settings' do
      [:npm_package, :conan_package, :nuget_package, :pypi_package, :composer_package, :generic_package, :golang_package, :debian_package].each do |format|
        let_it_be(:package) { create(format) } # rubocop:disable Rails/SaveBang
        let_it_be(:package_setting) { package.project.namespace.package_settings }

        it 'raises an error' do
          expect { subject }.to raise_error(Namespace::PackageSetting::PackageSettingNotImplemented)
        end
      end
    end
  end
end
