# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Dependency, type: :model, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }
  let_it_be(:project2) { create(:project) }

  describe 'included modules' do
    it { is_expected.to include_module(EachBatch) }
  end

  describe 'relationships' do
    it { is_expected.to have_many(:dependency_links) }
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    let_it_be(:dependency) { create(:packages_dependency) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:version_pattern) }
    it { is_expected.to validate_presence_of(:project_id) }

    context 'uniqueness' do
      let_it_be(:project) { create(:project) }

      subject(:new_record) do
        build(
          :packages_dependency,
          name: dependency.name,
          version_pattern: dependency.version_pattern,
          project: project
        )
      end

      context 'without project' do
        let_it_be(:project) { nil }

        it { is_expected.not_to be_valid }
      end

      context 'with project' do
        it { is_expected.to be_valid }

        context 'with another dependency in the same project' do
          let_it_be(:dependency) do
            create(
              :packages_dependency,
              name: dependency.name,
              version_pattern: dependency.version_pattern,
              project: project
            )
          end

          it { is_expected.not_to be_valid }
        end
      end
    end
  end

  describe '.ids_for_package_project_id_names_and_version_patterns' do
    let_it_be(:package_dependency1) do
      create(:packages_dependency, name: 'foo', version_pattern: '~1.0.0', project: project)
    end

    let_it_be(:package_dependency_diff_project) do
      create(:packages_dependency, name: 'bar', version_pattern: '~2.5.0', project: project2)
    end

    let_it_be(:expected_ids) { [package_dependency1.id] }

    let(:names_and_version_patterns) { build_names_and_version_patterns(package_dependency1) }
    let(:chunk_size) { 50 }
    let(:rows_limit) { 50 }

    subject do
      described_class.ids_for_package_project_id_names_and_version_patterns(
        project.id,
        names_and_version_patterns,
        chunk_size,
        rows_limit
      )
    end

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

      let(:names_and_version_patterns) { build_names_and_version_patterns(package_dependency1).merge(big_name => '~1.0.0') }

      it { is_expected.to match_array(expected_ids) }
    end

    context 'with a version pattern bigger than column size' do
      let_it_be(:big_version_pattern) { 'a' * (Packages::Dependency::MAX_STRING_LENGTH + 1) }

      let(:names_and_version_patterns) { build_names_and_version_patterns(package_dependency1).merge('test' => big_version_pattern) }

      it { is_expected.to match_array(expected_ids) }
    end

    context 'with too big parameter' do
      let(:size) { (Packages::Dependency::MAX_CHUNKED_QUERIES_COUNT * chunk_size) + 1 }
      let(:names_and_version_patterns) { (1..size).to_h { |v| [v, v] } }

      it { expect { subject }.to raise_error(ArgumentError, 'Too many names_and_version_patterns') }
    end

    context 'with parameters size' do
      let_it_be(:package_dependency2) do
        create(:packages_dependency, name: 'foo3', version_pattern: '~1.5.3', project: project)
      end

      let_it_be(:package_dependency3) do
        create(:packages_dependency, name: 'foo4', version_pattern: '~1.5.4', project: project)
      end

      let_it_be(:package_dependency4) do
        create(:packages_dependency, name: 'foo5', version_pattern: '~1.5.5', project: project)
      end

      let_it_be(:package_dependency5) do
        create(:packages_dependency, name: 'foo6', version_pattern: '~1.5.6', project: project)
      end

      let_it_be(:package_dependency6) do
        create(:packages_dependency, name: 'foo7', version_pattern: '~1.5.7', project: project)
      end

      let(:expected_ids) { [package_dependency1.id, package_dependency2.id, package_dependency3.id, package_dependency4.id, package_dependency5.id, package_dependency6.id] }
      let(:names_and_version_patterns) { build_names_and_version_patterns(package_dependency1, package_dependency2, package_dependency3, package_dependency4, package_dependency5, package_dependency6) }

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

  describe '.for_package_project_id_names_and_version_patterns' do
    let_it_be(:package_dependency1) do
      create(:packages_dependency, name: 'foo', version_pattern: '~1.0.0', project: project)
    end

    let_it_be(:package_dependency_diff_project) do
      create(:packages_dependency, name: 'bar', version_pattern: '~2.5.0', project: project2)
    end

    let_it_be(:expected_array) { [package_dependency1] }

    let(:names_and_version_patterns) { build_names_and_version_patterns(package_dependency1) }

    subject do
      described_class.for_package_project_id_names_and_version_patterns(project.id, names_and_version_patterns)
    end

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

  describe '.orphaned' do
    let_it_be(:orphaned_dependencies) { create_list(:packages_dependency, 2, project: project) }
    let_it_be(:linked_dependency) do
      create(:packages_dependency).tap do |dependency|
        create(:packages_dependency_link, dependency: dependency)
      end
    end

    it 'returns orphaned dependency records' do
      expect(described_class.orphaned).to contain_exactly(*orphaned_dependencies)
    end
  end

  def build_names_and_version_patterns(*package_dependencies)
    result = Hash.new { |h, dependency| h[dependency.name] = dependency.version_pattern }
    package_dependencies.each { |dependency| result[dependency] }
    result
  end
end
