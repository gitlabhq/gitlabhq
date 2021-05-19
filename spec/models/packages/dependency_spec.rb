# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Dependency, type: :model do
  describe 'relationships' do
    it { is_expected.to have_many(:dependency_links) }
  end

  describe 'validations' do
    subject { create(:packages_dependency) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:version_pattern) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:version_pattern) }
  end

  describe '.ids_for_package_names_and_version_patterns' do
    let_it_be(:package_dependency1) { create(:packages_dependency, name: 'foo', version_pattern: '~1.0.0') }
    let_it_be(:package_dependency2) { create(:packages_dependency, name: 'bar', version_pattern: '~2.5.0') }
    let_it_be(:expected_ids) { [package_dependency1.id, package_dependency2.id] }

    let(:names_and_version_patterns) { build_names_and_version_patterns(package_dependency1, package_dependency2) }
    let(:chunk_size) { 50 }
    let(:rows_limit) { 50 }

    subject { Packages::Dependency.ids_for_package_names_and_version_patterns(names_and_version_patterns, chunk_size, rows_limit) }

    it { is_expected.to match_array(expected_ids) }

    context 'with unknown names' do
      let(:names_and_version_patterns) { { unknown: '~1.0.0' } }

      it { is_expected.to be_empty }
    end

    context 'with unknown version patterns' do
      let(:names_and_version_patterns) { { 'foo' => '~1.0.0beta' } }

      it { is_expected.to be_empty }
    end

    context 'with a name bigger than column size' do
      let_it_be(:big_name) { 'a' * (Packages::Dependency::MAX_STRING_LENGTH + 1) }

      let(:names_and_version_patterns) { build_names_and_version_patterns(package_dependency1, package_dependency2).merge(big_name => '~1.0.0') }

      it { is_expected.to match_array(expected_ids) }
    end

    context 'with a version pattern bigger than column size' do
      let_it_be(:big_version_pattern) { 'a' * (Packages::Dependency::MAX_STRING_LENGTH + 1) }

      let(:names_and_version_patterns) { build_names_and_version_patterns(package_dependency1, package_dependency2).merge('test' => big_version_pattern) }

      it { is_expected.to match_array(expected_ids) }
    end

    context 'with too big parameter' do
      let(:size) { (Packages::Dependency::MAX_CHUNKED_QUERIES_COUNT * chunk_size) + 1 }
      let(:names_and_version_patterns) { (1..size).to_h { |v| [v, v] } }

      it { expect { subject }.to raise_error(ArgumentError, 'Too many names_and_version_patterns') }
    end

    context 'with parameters size' do
      let_it_be(:package_dependency3) { create(:packages_dependency, name: 'foo3', version_pattern: '~1.5.3') }
      let_it_be(:package_dependency4) { create(:packages_dependency, name: 'foo4', version_pattern: '~1.5.4') }
      let_it_be(:package_dependency5) { create(:packages_dependency, name: 'foo5', version_pattern: '~1.5.5') }
      let_it_be(:package_dependency6) { create(:packages_dependency, name: 'foo6', version_pattern: '~1.5.6') }
      let_it_be(:package_dependency7) { create(:packages_dependency, name: 'foo7', version_pattern: '~1.5.7') }

      let(:expected_ids) { [package_dependency1.id, package_dependency2.id, package_dependency3.id, package_dependency4.id, package_dependency5.id, package_dependency6.id, package_dependency7.id] }
      let(:names_and_version_patterns) { build_names_and_version_patterns(package_dependency1, package_dependency2, package_dependency3, package_dependency4, package_dependency5, package_dependency6, package_dependency7) }

      context 'above the chunk size' do
        let(:chunk_size) { 2 }

        it { is_expected.to match_array(expected_ids) }
      end

      context 'selecting too many rows' do
        let(:rows_limit) { 2 }

        it { expect { subject }.to raise_error(ArgumentError, 'Too many Dependencies selected') }
      end
    end
  end

  describe '.for_package_names_and_version_patterns' do
    let_it_be(:package_dependency1) { create(:packages_dependency, name: 'foo', version_pattern: '~1.0.0') }
    let_it_be(:package_dependency2) { create(:packages_dependency, name: 'bar', version_pattern: '~2.5.0') }
    let_it_be(:expected_array) { [package_dependency1, package_dependency2] }

    let(:names_and_version_patterns) { build_names_and_version_patterns(package_dependency1, package_dependency2) }

    subject { Packages::Dependency.for_package_names_and_version_patterns(names_and_version_patterns) }

    it { is_expected.to match_array(expected_array) }

    context 'with unknown names' do
      let(:names_and_version_patterns) { { unknown: '~1.0.0' } }

      it { is_expected.to be_empty }
    end

    context 'with unknown version patterns' do
      let(:names_and_version_patterns) { { 'foo' => '~1.0.0beta' } }

      it { is_expected.to be_empty }
    end
  end

  def build_names_and_version_patterns(*package_dependencies)
    result = Hash.new { |h, dependency| h[dependency.name] = dependency.version_pattern }
    package_dependencies.each { |dependency| result[dependency] }
    result
  end
end
