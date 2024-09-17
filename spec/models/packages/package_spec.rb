# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Package, type: :model, feature_category: :package_registry do
  include SortingHelper
  using RSpec::Parameterized::TableSyntax

  it_behaves_like 'having unique enum values'

  it { is_expected.to be_a Packages::Downloadable }

  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:creator) }
    it { is_expected.to have_many(:package_files).dependent(:destroy) }
    it { is_expected.to have_many(:dependency_links).inverse_of(:package) }
    it { is_expected.to have_many(:tags).inverse_of(:package) }
    it { is_expected.to have_many(:build_infos).inverse_of(:package) }
    it { is_expected.to have_many(:installable_nuget_package_files).inverse_of(:package) }
    it { is_expected.to have_one(:maven_metadatum).inverse_of(:package) }
    it { is_expected.to have_one(:nuget_metadatum).inverse_of(:package) }
    it { is_expected.to have_one(:npm_metadatum).inverse_of(:package) }
    it { is_expected.to have_one(:terraform_module_metadatum).inverse_of(:package) }
    it { is_expected.to have_many(:nuget_symbols).inverse_of(:package) }
    it { is_expected.to have_many(:matching_package_protection_rules).through(:project).source(:package_protection_rules) }
  end

  describe '.sort_by_attribute' do
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:project) { create(:project, :public, namespace: group, name: 'project A', path: 'project-a') }

    let!(:package1) { create(:npm_package, project: project, version: '3.1.0', name: "@#{project.root_namespace.path}/foo1") }
    let!(:package2) { create(:nuget_package, project: project, version: '2.0.4') }
    let(:package3) { create(:maven_package, project: project, version: '1.1.1', name: 'zzz') }

    before do
      travel_to(1.day.ago) do
        package3
      end
    end

    RSpec.shared_examples 'package sorting by attribute' do |order_by|
      subject { described_class.where(id: packages.map(&:id)).sort_by_attribute("#{order_by}_#{sort}").to_a }

      let(:packages_desc) { packages.reverse }

      context "sorting by #{order_by}" do
        context 'ascending order' do
          let(:sort) { 'asc' }

          it { is_expected.to eq packages }
        end

        context 'descending order' do
          let(:sort) { 'desc' }

          it { is_expected.to eq(packages_desc) }
        end
      end
    end

    it_behaves_like 'package sorting by attribute', 'name' do
      let(:packages) { [package1, package2, package3] }
    end

    it_behaves_like 'package sorting by attribute', 'created_at' do
      let(:packages) { [package3, package1, package2] }
    end

    it_behaves_like 'package sorting by attribute', 'version' do
      let(:packages) { [package3, package2, package1] }
    end

    it_behaves_like 'package sorting by attribute', 'type' do
      let(:packages) { [package3, package1, package2] }
    end

    it_behaves_like 'package sorting by attribute', 'project_path' do
      let_it_be(:another_project) { create(:project, :public, namespace: group, name: 'project B', path: 'project-b') }
      let_it_be(:package4) { create(:npm_package, project: another_project, version: '3.1.0', name: "@#{project.root_namespace.path}/bar") }

      let(:packages) { [package3, package2, package1, package4] }
      let(:packages_desc) { [package4, package3, package2, package1] }
    end
  end

  describe '.for_projects' do
    let_it_be(:package1) { create(:maven_package) }
    let_it_be(:package2) { create(:maven_package) }
    let_it_be(:package3) { create(:maven_package) }

    let(:projects) { ::Project.id_in([package1.project_id, package2.project_id]) }

    subject { described_class.for_projects(projects.select(:id)) }

    it 'returns package1 and package2' do
      expect(projects).not_to receive(:any?)

      expect(subject).to match_array([package1, package2])
    end
  end

  describe 'validations' do
    subject { build(:package) }

    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:project_id, :version, :package_type) }

    describe '#name' do
      it { is_expected.to allow_value("my/domain/com/my-app").for(:name) }
      it { is_expected.to allow_value("my.app-11.07.2018").for(:name) }
      it { is_expected.not_to allow_value("my(dom$$$ain)com.my-app").for(:name) }

      context 'nuget package' do
        subject { build_stubbed(:nuget_package) }

        it { is_expected.to allow_value('My.Package').for(:name) }
        it { is_expected.to allow_value('My.Package.Mvc').for(:name) }
        it { is_expected.to allow_value('MyPackage').for(:name) }
        it { is_expected.to allow_value('My.23.Package').for(:name) }
        it { is_expected.to allow_value('My23Package').for(:name) }
        it { is_expected.to allow_value('runtime.my-test64.runtime.package.Mvc').for(:name) }
        it { is_expected.to allow_value('my_package').for(:name) }
        it { is_expected.not_to allow_value('My/package').for(:name) }
        it { is_expected.not_to allow_value('../../../my_package').for(:name) }
        it { is_expected.not_to allow_value('%2e%2e%2fmy_package').for(:name) }
      end

      context 'npm package' do
        subject { build_stubbed(:npm_package) }

        it { is_expected.to allow_value("@group-1/package").for(:name) }
        it { is_expected.to allow_value("@any-scope/package").for(:name) }
        it { is_expected.to allow_value("unscoped-package").for(:name) }
        it { is_expected.not_to allow_value("@inv@lid-scope/package").for(:name) }
        it { is_expected.not_to allow_value("@scope/../../package").for(:name) }
        it { is_expected.not_to allow_value("@scope%2e%2e%fpackage").for(:name) }
        it { is_expected.not_to allow_value("@scope/sub/package").for(:name) }
      end

      context 'terraform module package' do
        subject { build_stubbed(:terraform_module_package) }

        it { is_expected.to allow_value('my-module/my-system').for(:name) }
        it { is_expected.to allow_value('my/module').for(:name) }
        it { is_expected.not_to allow_value('my-module').for(:name) }
        it { is_expected.not_to allow_value('My-Module').for(:name) }
        it { is_expected.not_to allow_value('my_module').for(:name) }
        it { is_expected.not_to allow_value('my.module').for(:name) }
        it { is_expected.not_to allow_value('../../../my-module').for(:name) }
        it { is_expected.not_to allow_value('%2e%2e%2fmy-module').for(:name) }
      end
    end

    describe '#version' do
      context 'maven package' do
        subject { build_stubbed(:maven_package) }

        it { is_expected.to allow_value('0').for(:version) }
        it { is_expected.to allow_value('1').for(:version) }
        it { is_expected.to allow_value('10').for(:version) }
        it { is_expected.to allow_value('1.0').for(:version) }
        it { is_expected.to allow_value('1.3.350.v20200505-1744').for(:version) }
        it { is_expected.to allow_value('1.1-beta-2').for(:version) }
        it { is_expected.to allow_value('1.2-SNAPSHOT').for(:version) }
        it { is_expected.to allow_value('12.1.2-2-1').for(:version) }
        it { is_expected.to allow_value('1.2.3-beta').for(:version) }
        it { is_expected.to allow_value('10.2.3-beta').for(:version) }
        it { is_expected.to allow_value('2.0.0.v200706041905-7C78EK9E_EkMNfNOd2d8qq').for(:version) }
        it { is_expected.to allow_value('1.2-alpha-1-20050205.060708-1').for(:version) }
        it { is_expected.to allow_value('703220b4e2cea9592caeb9f3013f6b1e5335c293').for(:version) }
        it { is_expected.to allow_value('RELEASE').for(:version) }
        it { is_expected.not_to allow_value('..1.2.3').for(:version) }
        it { is_expected.not_to allow_value('1.2.3..beta').for(:version) }
        it { is_expected.not_to allow_value('  1.2.3').for(:version) }
        it { is_expected.not_to allow_value("1.2.3  \r\t").for(:version) }
        it { is_expected.not_to allow_value("\r\t 1.2.3").for(:version) }
        it { is_expected.not_to allow_value('1.2.3-4/../../').for(:version) }
        it { is_expected.not_to allow_value('1.2.3-4%2e%2e%').for(:version) }
        it { is_expected.not_to allow_value('../../../../../1.2.3').for(:version) }
        it { is_expected.not_to allow_value('%2e%2e%2f1.2.3').for(:version) }
      end

      context 'pypi package' do
        subject { create(:pypi_package) }

        it { is_expected.to allow_value('0.1').for(:version) }
        it { is_expected.to allow_value('2.0').for(:version) }
        it { is_expected.to allow_value('1.2.0').for(:version) }
        it { is_expected.to allow_value('0100!0.0').for(:version) }
        it { is_expected.to allow_value('00!1.2').for(:version) }
        it { is_expected.to allow_value('1.0a').for(:version) }
        it { is_expected.to allow_value('1.0-a').for(:version) }
        it { is_expected.to allow_value('1.0.a1').for(:version) }
        it { is_expected.to allow_value('1.0a1').for(:version) }
        it { is_expected.to allow_value('1.0-a1').for(:version) }
        it { is_expected.to allow_value('1.0alpha1').for(:version) }
        it { is_expected.to allow_value('1.0b1').for(:version) }
        it { is_expected.to allow_value('1.0beta1').for(:version) }
        it { is_expected.to allow_value('1.0rc1').for(:version) }
        it { is_expected.to allow_value('1.0pre1').for(:version) }
        it { is_expected.to allow_value('1.0preview1').for(:version) }
        it { is_expected.to allow_value('1.0.dev1').for(:version) }
        it { is_expected.to allow_value('1.0.DEV1').for(:version) }
        it { is_expected.to allow_value('1.0.post1').for(:version) }
        it { is_expected.to allow_value('1.0.rev1').for(:version) }
        it { is_expected.to allow_value('1.0.r1').for(:version) }
        it { is_expected.to allow_value('1.0c2').for(:version) }
        it { is_expected.to allow_value('2012.15').for(:version) }
        it { is_expected.to allow_value('1.0+5').for(:version) }
        it { is_expected.to allow_value('1.0+abc.5').for(:version) }
        it { is_expected.to allow_value('1!1.1').for(:version) }
        it { is_expected.to allow_value('1.0c3').for(:version) }
        it { is_expected.to allow_value('1.0rc2').for(:version) }
        it { is_expected.to allow_value('1.0c1').for(:version) }
        it { is_expected.to allow_value('1.0b2-346').for(:version) }
        it { is_expected.to allow_value('1.0b2.post345').for(:version) }
        it { is_expected.to allow_value('1.0b2.post345.dev456').for(:version) }
        it { is_expected.to allow_value('1.2.rev33+123456').for(:version) }
        it { is_expected.to allow_value('1.1.dev1').for(:version) }
        it { is_expected.to allow_value('1.0b1.dev456').for(:version) }
        it { is_expected.to allow_value('1.0a12.dev456').for(:version) }
        it { is_expected.to allow_value('1.0b2').for(:version) }
        it { is_expected.to allow_value('1.0.dev456').for(:version) }
        it { is_expected.to allow_value('1.0c1.dev456').for(:version) }
        it { is_expected.to allow_value('1.0.post456').for(:version) }
        it { is_expected.to allow_value('1.0.post456.dev34').for(:version) }
        it { is_expected.to allow_value('1.2+123abc').for(:version) }
        it { is_expected.to allow_value('1.2+abc').for(:version) }
        it { is_expected.to allow_value('1.2+abc123').for(:version) }
        it { is_expected.to allow_value('1.2+abc123def').for(:version) }
        it { is_expected.to allow_value('1.2+1234.abc').for(:version) }
        it { is_expected.to allow_value('1.2+123456').for(:version) }
        it { is_expected.to allow_value('1.2.r32+123456').for(:version) }
        it { is_expected.to allow_value('1!1.2.rev33+123456').for(:version) }
        it { is_expected.to allow_value('1.0a12').for(:version) }
        it { is_expected.to allow_value('1.2.3-45+abcdefgh').for(:version) }
        it { is_expected.to allow_value('v1.2.3').for(:version) }
        it { is_expected.not_to allow_value('1.2.3-45-abcdefgh').for(:version) }
        it { is_expected.not_to allow_value('..1.2.3').for(:version) }
        it { is_expected.not_to allow_value('  1.2.3').for(:version) }
        it { is_expected.not_to allow_value("1.2.3  \r\t").for(:version) }
        it { is_expected.not_to allow_value("\r\t 1.2.3").for(:version) }
        it { is_expected.not_to allow_value('1./2.3').for(:version) }
        it { is_expected.not_to allow_value('1.2.3-4/../../').for(:version) }
        it { is_expected.not_to allow_value('1.2.3-4%2e%2e%').for(:version) }
        it { is_expected.not_to allow_value('../../../../../1.2.3').for(:version) }
        it { is_expected.not_to allow_value('%2e%2e%2f1.2.3').for(:version) }
      end

      it_behaves_like 'validating version to be SemVer compliant for', :npm_package
      it_behaves_like 'validating version to be SemVer compliant for', :terraform_module_package

      context 'nuget package' do
        subject { build_stubbed(:nuget_package) }

        it { is_expected.to allow_value('1.2').for(:version) }
        it { is_expected.to allow_value('1.2.3').for(:version) }
        it { is_expected.to allow_value('1.2.3.4').for(:version) }
        it { is_expected.to allow_value('1.2.3-beta').for(:version) }
        it { is_expected.to allow_value('1.2.3-alpha.3').for(:version) }
        it { is_expected.not_to allow_value('1').for(:version) }
        it { is_expected.not_to allow_value('1./2.3').for(:version) }
        it { is_expected.not_to allow_value('../../../../../1.2.3').for(:version) }
        it { is_expected.not_to allow_value('%2e%2e%2f1.2.3').for(:version) }
      end
    end

    describe '#npm_package_already_taken' do
      context 'maven package' do
        let!(:package) { create(:maven_package) }

        it 'will allow a package of the same name' do
          new_package = build(:maven_package, name: package.name)

          expect(new_package).to be_valid
        end
      end

      context 'npm package' do
        let_it_be(:group) { create(:group) }
        let_it_be(:project) { create(:project, namespace: group) }
        let_it_be(:second_project) { create(:project, namespace: group) }

        let(:package) { build(:npm_package, project: project, name: name) }

        shared_examples 'validating the first package' do
          it 'validates the first package' do
            expect(package).to be_valid
          end
        end

        shared_examples 'validating the second package' do
          it 'validates the second package' do
            package.save!

            expect(second_package).to be_valid
          end
        end

        shared_examples 'not validating the second package' do |field_with_error:|
          it 'does not validate the second package' do
            package.save!

            expect(second_package).not_to be_valid
            case field_with_error
            when :base
              expect(second_package.errors.messages[:base]).to eq ['Package already exists']
            when :name
              expect(second_package.errors.messages[:name]).to eq ['has already been taken']
            else
              raise ArgumentError, "field #{field_with_error} not expected"
            end
          end
        end

        shared_examples 'validating both if the first package is pending destruction' do
          before do
            package.status = :pending_destruction
          end

          it_behaves_like 'validating the first package'
          it_behaves_like 'validating the second package'
        end

        context 'following the naming convention' do
          let(:name) { "@#{group.path}/test" }

          context 'with the second package in the project of the first package' do
            let(:second_package) { build(:npm_package, project: project, name: second_package_name, version: second_package_version) }

            context 'with no duplicated name' do
              let(:second_package_name) { "@#{group.path}/test2" }
              let(:second_package_version) { '5.0.0' }

              it_behaves_like 'validating the first package'
              it_behaves_like 'validating the second package'
            end

            context 'with duplicated name' do
              let(:second_package_name) { package.name }
              let(:second_package_version) { '5.0.0' }

              it_behaves_like 'validating the first package'
              it_behaves_like 'validating the second package'
            end

            context 'with duplicate name and duplicated version' do
              let(:second_package_name) { package.name }
              let(:second_package_version) { package.version }

              it_behaves_like 'validating the first package'
              it_behaves_like 'not validating the second package', field_with_error: :name
              it_behaves_like 'validating both if the first package is pending destruction'
            end
          end

          context 'with the second package in a different project than the first package' do
            let(:second_package) { build(:npm_package, project: second_project, name: second_package_name, version: second_package_version) }

            context 'with no duplicated name' do
              let(:second_package_name) { "@#{group.path}/test2" }
              let(:second_package_version) { '5.0.0' }

              it_behaves_like 'validating the first package'
              it_behaves_like 'validating the second package'
            end

            context 'with duplicated name' do
              let(:second_package_name) { package.name }
              let(:second_package_version) { '5.0.0' }

              it_behaves_like 'validating the first package'
              it_behaves_like 'validating the second package'
            end

            context 'with duplicate name and duplicated version' do
              let(:second_package_name) { package.name }
              let(:second_package_version) { package.version }

              it_behaves_like 'validating the first package'
              it_behaves_like 'not validating the second package', field_with_error: :base
              it_behaves_like 'validating both if the first package is pending destruction'
            end
          end
        end

        context 'not following the naming convention' do
          let(:name) { '@foobar/test' }

          context 'with the second package in the project of the first package' do
            let(:second_package) { build(:npm_package, project: project, name: second_package_name, version: second_package_version) }

            context 'with no duplicated name' do
              let(:second_package_name) { "@foobar/test2" }
              let(:second_package_version) { '5.0.0' }

              it_behaves_like 'validating the first package'
              it_behaves_like 'validating the second package'
            end

            context 'with duplicated name' do
              let(:second_package_name) { package.name }
              let(:second_package_version) { '5.0.0' }

              it_behaves_like 'validating the first package'
              it_behaves_like 'validating the second package'
            end

            context 'with duplicate name and duplicated version' do
              let(:second_package_name) { package.name }
              let(:second_package_version) { package.version }

              it_behaves_like 'validating the first package'
              it_behaves_like 'not validating the second package', field_with_error: :name
              it_behaves_like 'validating both if the first package is pending destruction'
            end
          end

          context 'with the second package in a different project than the first package' do
            let(:second_package) { build(:npm_package, project: second_project, name: second_package_name, version: second_package_version) }

            context 'with no duplicated name' do
              let(:second_package_name) { "@foobar/test2" }
              let(:second_package_version) { '5.0.0' }

              it_behaves_like 'validating the first package'
              it_behaves_like 'validating the second package'
            end

            context 'with duplicated name' do
              let(:second_package_name) { package.name }
              let(:second_package_version) { '5.0.0' }

              it_behaves_like 'validating the first package'
              it_behaves_like 'validating the second package'
            end

            context 'with duplicate name and duplicated version' do
              let(:second_package_name) { package.name }
              let(:second_package_version) { package.version }

              it_behaves_like 'validating the first package'
              it_behaves_like 'validating the second package'
              it_behaves_like 'validating both if the first package is pending destruction'
            end
          end
        end
      end
    end

    Packages::Package.package_types.keys.without('conan').each do |pt|
      context "project id, name, version and package type uniqueness for package type #{pt}" do
        let(:package) { create("#{pt}_package") }

        it "will not allow a #{pt} package with same project, name, version and package_type" do
          new_package = build("#{pt}_package", project: package.project, name: package.name, version: package.version)
          expect(new_package).not_to be_valid
          expect(new_package.errors.to_a).to include("Name has already been taken")
        end

        context 'with pending_destruction package' do
          let!(:package) { create("#{pt}_package", :pending_destruction) }

          it "will allow a #{pt} package with same project, name, version and package_type" do
            new_package = build("#{pt}_package", project: package.project, name: package.name, version: package.version)
            expect(new_package).to be_valid
          end
        end
      end
    end
  end

  describe '#destroy' do
    let(:package) { create(:npm_package) }
    let(:package_file) { package.package_files.first }
    let(:project_statistics) { package.project.statistics }

    subject(:destroy!) { package.destroy! }

    it 'updates the project statistics' do
      expect(project_statistics).to receive(:increment_counter).with(:packages_size, have_attributes(amount: -package_file.size))

      destroy!
    end
  end

  describe '.by_name_and_file_name' do
    let!(:package) { create(:npm_package) }
    let!(:package_file) { package.package_files.first }

    subject { described_class }

    it 'finds a package with correct arguiments' do
      expect(subject.by_name_and_file_name(package.name, package_file.file_name)).to eq(package)
    end

    it 'will raise error if not found' do
      expect { subject.by_name_and_file_name('foo', 'foo-5.5.5.tgz') }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '.with_package_type' do
    let!(:package1) { create(:terraform_module_package) }
    let!(:package2) { create(:npm_package) }
    let(:package_type) { :terraform_module }

    subject { described_class.with_package_type(package_type) }

    it { is_expected.to eq([package1]) }
  end

  describe '.without_package_type' do
    let!(:package1) { create(:npm_package) }
    let!(:package2) { create(:terraform_module_package) }
    let(:package_type) { :terraform_module }

    subject { described_class.without_package_type(package_type) }

    it { is_expected.to eq([package1]) }
  end

  context 'version scopes' do
    let!(:package1) { create(:npm_package, version: '1.0.0') }
    let!(:package2) { create(:npm_package, version: '1.0.1') }
    let!(:package3) { create(:npm_package, version: '1.0.1') }

    describe '.has_version' do
      subject { described_class.has_version }

      before do
        create(:maven_metadatum).package.update!(version: nil)
      end

      it 'includes only packages with version attribute' do
        is_expected.to match_array([package1, package2, package3])
      end
    end

    describe '.with_version' do
      subject { described_class.with_version('1.0.1') }

      it 'includes only packages with specified version' do
        is_expected.to match_array([package2, package3])
      end
    end

    describe '.without_version_like' do
      let(:version_pattern) { '%.0.0%' }

      subject { described_class.without_version_like(version_pattern) }

      it 'includes packages without the version pattern' do
        is_expected.to match_array([package2, package3])
      end
    end
  end

  describe '.with_npm_scope' do
    let_it_be(:package1) { create(:npm_package, name: '@test/foobar') }
    let_it_be(:package2) { create(:npm_package, name: '@test2/foobar') }
    let_it_be(:package3) { create(:npm_package, name: 'foobar') }

    subject { described_class.with_npm_scope('test') }

    it { is_expected.to contain_exactly(package1) }
  end

  describe '.without_nuget_temporary_name' do
    let!(:package1) { create(:nuget_package) }
    let!(:package2) { create(:nuget_package, name: Packages::Nuget::TEMPORARY_PACKAGE_NAME) }

    subject { described_class.without_nuget_temporary_name }

    it 'does not include nuget temporary packages' do
      expect(subject).to eq([package1])
    end
  end

  describe '.limit_recent' do
    let!(:package1) { create(:nuget_package) }
    let!(:package2) { create(:nuget_package) }
    let!(:package3) { create(:nuget_package) }

    subject { described_class.limit_recent(2) }

    it { is_expected.to match_array([package3, package2]) }
  end

  context 'with several packages' do
    let_it_be(:package1) { create(:nuget_package, name: 'FooBar') }
    let_it_be(:package2) { create(:nuget_package, name: 'foobar') }
    let_it_be(:package3) { create(:npm_package) }
    let_it_be(:package4) { create(:npm_package) }

    describe '.pluck_names' do
      subject { described_class.pluck_names }

      it { is_expected.to match_array([package1, package2, package3, package4].map(&:name)) }
    end

    describe '.pluck_versions' do
      subject { described_class.pluck_versions }

      it { is_expected.to match_array([package1, package2, package3, package4].map(&:version)) }
    end

    describe '.with_name_like' do
      subject { described_class.with_name_like(name_term) }

      context 'with downcase name' do
        let(:name_term) { 'foobar' }

        it { is_expected.to match_array([package1, package2]) }
      end

      context 'with prefix wildcard' do
        let(:name_term) { '%ar' }

        it { is_expected.to match_array([package1, package2]) }
      end

      context 'with suffix wildcard' do
        let(:name_term) { 'foo%' }

        it { is_expected.to match_array([package1, package2]) }
      end

      context 'with surrounding wildcards' do
        let(:name_term) { '%ooba%' }

        it { is_expected.to match_array([package1, package2]) }
      end
    end

    describe '.search_by_name' do
      let(:query) { 'oba' }

      subject { described_class.search_by_name(query) }

      it { is_expected.to match_array([package1, package2]) }
    end

    describe '.with_normalized_pypi_name' do
      let_it_be(:pypi_package) { create(:pypi_package, name: 'Foo.bAr---BAZ_buz') }

      subject { described_class.with_normalized_pypi_name('foo-bar-baz-buz') }

      it { is_expected.to match_array([pypi_package]) }
    end

    describe '.with_case_insensitive_version' do
      let_it_be(:nuget_package) { create(:nuget_package, version: '1.0.0-ABC') }

      subject { described_class.with_case_insensitive_version('1.0.0-abC') }

      it { is_expected.to match_array([nuget_package]) }
    end

    describe '.with_case_insensitive_name' do
      let_it_be(:nuget_package) { create(:nuget_package, name: 'TestPackage') }

      subject { described_class.with_case_insensitive_name('testpackage') }

      it { is_expected.to match_array([nuget_package]) }
    end

    describe '.with_nuget_version_or_normalized_version' do
      let_it_be(:nuget_package) { create(:nuget_package, :with_metadatum, version: '1.0.7+r3456') }

      before do
        nuget_package.nuget_metadatum.update_column(:normalized_version, '1.0.7')
      end

      subject { described_class.with_nuget_version_or_normalized_version(version, with_normalized: with_normalized) }

      where(:version, :with_normalized, :expected) do
        '1.0.7'       | true  | [ref(:nuget_package)]
        '1.0.7'       | false | []
        '1.0.7+r3456' | true  | [ref(:nuget_package)]
        '1.0.7+r3456' | false | [ref(:nuget_package)]
      end

      with_them do
        it { is_expected.to match_array(expected) }
      end
    end

    context 'status scopes' do
      let_it_be(:default_package) { create(:maven_package, :default) }
      let_it_be(:hidden_package) { create(:maven_package, :hidden) }
      let_it_be(:processing_package) { create(:maven_package, :processing) }
      let_it_be(:error_package) { create(:maven_package, :error) }

      describe '.displayable' do
        subject { described_class.displayable }

        it 'does not include non-displayable packages', :aggregate_failures do
          is_expected.to include(error_package)
          is_expected.not_to include(hidden_package)
          is_expected.not_to include(processing_package)
        end
      end

      describe '.installable' do
        it_behaves_like 'installable packages', :maven_package
      end

      describe '.with_status' do
        subject { described_class.with_status(:hidden) }

        it 'returns packages with specified status' do
          is_expected.to match_array([hidden_package])
        end
      end
    end
  end

  describe '.select_distinct_name' do
    let_it_be(:nuget_package) { create(:nuget_package) }
    let_it_be(:nuget_packages) { create_list(:nuget_package, 3, name: nuget_package.name, project: nuget_package.project) }
    let_it_be(:maven_package) { create(:maven_package) }
    let_it_be(:maven_packages) { create_list(:maven_package, 3, name: maven_package.name, project: maven_package.project) }

    subject { described_class.select_distinct_name }

    it 'returns only distinct names' do
      packages = subject

      expect(packages.size).to eq(2)
      expect(packages.pluck(:name)).to match_array([nuget_package.name, maven_package.name])
    end
  end

  context 'sorting' do
    let_it_be(:project) { create(:project, path: 'aaa') }
    let_it_be(:project2) { create(:project, path: 'bbb') }
    let_it_be(:package1) { create(:package, project: project) }
    let_it_be(:package2) { create(:package, project: project2) }

    it 'orders packages by their projects name ascending' do
      expect(described_class.order_project_name).to eq([package1, package2])
    end

    it 'orders packages by their projects name descending' do
      expect(described_class.order_project_name_desc).to eq([package2, package1])
    end

    context 'with additional packages' do
      let_it_be(:package3) { create(:package, project: project2) }
      let_it_be(:package4) { create(:package, project: project) }

      it 'orders packages by their projects path asc, then package id desc' do
        expect(described_class.order_project_path).to eq([package4, package1, package3, package2])
      end

      it 'orders packages by their projects path desc, then package id desc' do
        expect(described_class.order_project_path_desc).to eq([package3, package2, package4, package1])
      end
    end
  end

  describe '.order_by_package_file' do
    let_it_be(:project) { create(:project) }
    let_it_be(:package1) { create(:maven_package, project: project) }
    let_it_be(:package2) { create(:maven_package, project: project) }

    it 'orders packages their associated package_file\'s created_at date', :aggregate_failures do
      expect(project.packages.order_by_package_file).to match_array([package1, package1, package1, package2, package2, package2])

      create(:package_file, :xml, package: package1)

      expect(project.packages.order_by_package_file).to match_array([package1, package1, package1, package2, package2, package2, package1])
    end
  end

  describe '.preload_tags' do
    let_it_be(:package) { create(:npm_package) }
    let_it_be(:tags) { create_list(:packages_tag, 2, package: package) }

    subject { described_class.preload_tags }

    it 'preloads tags' do
      expect(subject.first.association(:tags)).to be_loaded
    end
  end

  describe '.installable_statuses' do
    it_behaves_like 'installable statuses'
  end

  describe '#versions' do
    let_it_be(:project) { create(:project) }
    let_it_be(:package) { create(:maven_package, project: project) }
    let_it_be(:package2) { create(:maven_package, project: project) }
    let_it_be(:package3) { create(:maven_package, :error, project: project) }
    let_it_be(:package4) { create(:maven_package, project: project, name: 'foo') }
    let_it_be(:pending_destruction_package) { create(:maven_package, :pending_destruction, project: project) }

    it 'returns other package versions of the same package name belonging to the project' do
      expect(package.versions).to contain_exactly(package2, package3)
    end

    it 'does not return different packages' do
      expect(package.versions).not_to include(package4)
    end
  end

  describe '#pipeline' do
    let_it_be_with_refind(:package) { create(:maven_package) }

    context 'package without pipeline' do
      it 'returns nil if there is no pipeline' do
        expect(package.pipeline).to be_nil
      end
    end

    context 'package with pipeline' do
      let_it_be(:pipeline) { create(:ci_pipeline) }

      before do
        package.build_infos.create!(pipeline: pipeline)
      end

      it 'returns the pipeline' do
        expect(package.pipeline).to eq(pipeline)
      end
    end
  end

  describe '#pipelines' do
    let_it_be_with_refind(:package) { create(:maven_package) }

    subject { package.pipelines }

    context 'package without pipeline' do
      it { is_expected.to be_empty }
    end

    context 'package with pipeline' do
      let_it_be(:pipeline) { create(:ci_pipeline) }
      let_it_be(:pipeline2) { create(:ci_pipeline) }

      before do
        package.build_infos.create!(pipeline: pipeline)
        package.build_infos.create!(pipeline: pipeline2)
      end

      it { is_expected.to contain_exactly(pipeline, pipeline2) }
    end
  end

  describe '#matching_package_protection_rules' do
    let_it_be(:package) do
      create(:npm_package, name: 'npm-package')
    end

    let_it_be(:package_protection_rule) do
      create(:package_protection_rule, project: package.project, package_name_pattern: package.name, package_type: :npm,
        minimum_access_level_for_push: :maintainer)
    end

    let_it_be(:package_protection_rule_no_match) do
      create(:package_protection_rule, project: package.project, package_name_pattern: "other-#{package.name}", package_type: :npm,
        minimum_access_level_for_push: :maintainer)
    end

    subject { package.matching_package_protection_rules }

    it { is_expected.to eq [package_protection_rule] }
  end

  describe '#tag_names' do
    let_it_be(:package) { create(:nuget_package) }

    subject { package.tag_names }

    it { is_expected.to eq([]) }

    context 'with tags' do
      let(:tags) { %w[tag1 tag2 tag3] }

      before do
        tags.each { |t| create(:packages_tag, name: t, package: package) }
      end

      it { is_expected.to contain_exactly(*tags) }
    end
  end

  describe '#infrastructure_package?' do
    let(:package) { create(:package) }

    subject { package.infrastructure_package? }

    it { is_expected.to eq(false) }

    context 'with generic package' do
      let(:package) { create(:generic_package) }

      it { is_expected.to eq(false) }
    end

    context 'with terraform module package' do
      let(:package) { create(:terraform_module_package) }

      it { is_expected.to eq(true) }
    end
  end

  describe 'plan_limits' do
    Packages::Package.package_types.keys.without('composer').each do |pt|
      plan_limit_name = if pt == 'generic'
                          "#{pt}_packages_max_file_size"
                        else
                          "#{pt}_max_file_size"
                        end

      context "File size limits for #{pt}" do
        let(:package) { create("#{pt}_package") }

        it "plan_limits includes column #{plan_limit_name}" do
          expect { package.project.actual_limits.send(plan_limit_name) }
            .not_to raise_error
        end
      end
    end
  end

  describe '#last_build_info' do
    let_it_be_with_refind(:package) { create(:npm_package) }

    context 'without build_infos' do
      it 'returns nil' do
        expect(package.last_build_info).to be_nil
      end
    end

    context 'with build_infos' do
      let_it_be(:first_build_info) { create(:package_build_info, :with_pipeline, package: package) }
      let_it_be(:second_build_info) { create(:package_build_info, :with_pipeline, package: package) }

      it 'returns the last build info' do
        expect(package.last_build_info).to eq(second_build_info)
      end
    end
  end

  describe '#package_settings' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:package) { create(:maven_package, project: project) }

    it 'returns the namespace package_settings' do
      expect(package.package_settings).to eq(group.package_settings)
    end
  end

  describe '#sync_maven_metadata' do
    let_it_be(:user) { create(:user) }
    let_it_be(:package) { create(:maven_package) }

    subject { package.sync_maven_metadata(user) }

    shared_examples 'not enqueuing a sync worker job' do
      it 'does not enqueue a sync worker job' do
        expect(::Packages::Maven::Metadata::SyncWorker)
          .not_to receive(:perform_async)

        subject
      end
    end

    it 'enqueues a sync worker job' do
      expect(::Packages::Maven::Metadata::SyncWorker)
        .to receive(:perform_async).with(user.id, package.project.id, package.name)

      subject
    end

    context 'with no user' do
      let(:user) { nil }

      it_behaves_like 'not enqueuing a sync worker job'
    end

    context 'with a versionless maven package' do
      let_it_be(:package) { create(:maven_package, version: nil) }

      it_behaves_like 'not enqueuing a sync worker job'
    end

    context 'with a non maven package' do
      let_it_be(:package) { create(:npm_package) }

      it_behaves_like 'not enqueuing a sync worker job'
    end
  end

  describe '#sync_npm_metadata_cache' do
    let_it_be(:package) { create(:npm_package) }

    subject { package.sync_npm_metadata_cache }

    it 'enqueues a sync worker job' do
      expect(::Packages::Npm::CreateMetadataCacheWorker)
        .to receive(:perform_async).with(package.project_id, package.name)

      subject
    end

    context 'with a non npm package' do
      let_it_be(:package) { create(:maven_package) }

      it 'does not enqueue a sync worker job' do
        expect(::Packages::Npm::CreateMetadataCacheWorker)
          .not_to receive(:perform_async)

        subject
      end
    end
  end

  describe '#mark_package_files_for_destruction' do
    let_it_be(:package) { create(:npm_package, :pending_destruction) }

    subject { package.mark_package_files_for_destruction }

    it 'enqueues a sync worker job' do
      expect(::Packages::MarkPackageFilesForDestructionWorker)
        .to receive(:perform_async).with(package.id)

      subject
    end

    context 'for a package non pending destruction' do
      let_it_be(:package) { create(:npm_package) }

      it 'does not enqueues a sync worker job' do
        expect(::Packages::MarkPackageFilesForDestructionWorker)
        .not_to receive(:perform_async).with(package.id)

        subject
      end
    end
  end

  describe '#create_build_infos!' do
    let_it_be(:package) { create(:package) }
    let_it_be(:pipeline) { create(:ci_pipeline) }

    let(:build) { double(pipeline: pipeline) }

    subject { package.create_build_infos!(build) }

    context 'with a valid build' do
      it 'creates a build info' do
        expect { subject }.to change { ::Packages::BuildInfo.count }.by(1)

        last_build = ::Packages::BuildInfo.last
        expect(last_build.package).to eq(package)
        expect(last_build.pipeline).to eq(pipeline)
      end

      context 'with an already existing build info' do
        let_it_be(:build_info) { create(:package_build_info, package: package, pipeline: pipeline) }

        it 'does not create a build info' do
          expect { subject }.not_to change { ::Packages::BuildInfo.count }
        end
      end
    end

    context 'with a nil build' do
      let(:build) { nil }

      it 'does not create a build info' do
        expect { subject }.not_to change { ::Packages::BuildInfo.count }
      end
    end

    context 'with a build without a pipeline' do
      let(:build) { double(pipeline: nil) }

      it 'does not create a build info' do
        expect { subject }.not_to change { ::Packages::BuildInfo.count }
      end
    end
  end

  context 'with identical pending destruction package' do
    described_class.package_types.keys.each do |package_format|
      context "for package format #{package_format}" do
        let_it_be(:package_pending_destruction) { create("#{package_format}_package", :pending_destruction) }

        let(:new_package) { build("#{package_format}_package", name: package_pending_destruction.name, version: package_pending_destruction.version, project: package_pending_destruction.project) }

        it { expect(new_package).to be_valid }
      end
    end
  end

  describe '#normalized_pypi_name' do
    let_it_be(:package) { create(:pypi_package) }

    subject { package.normalized_pypi_name }

    where(:package_name, :normalized_name) do
      'ASDF' | 'asdf'
      'a.B_c-d' | 'a-b-c-d'
      'a-------b....c___d' | 'a-b-c-d'
    end

    with_them do
      before do
        package.update_column(:name, package_name)
      end

      it { is_expected.to eq(normalized_name) }
    end
  end

  describe '#normalized_nuget_version' do
    let_it_be(:package) { create(:nuget_package, :with_metadatum, version: '1.0') }
    let(:normalized_version) { '1.0.0' }

    subject { package.normalized_nuget_version }

    before do
      package.nuget_metadatum.update_column(:normalized_version, normalized_version)
    end

    it { is_expected.to eq(normalized_version) }
  end

  describe '#publish_creation_event' do
    let_it_be(:project) { create(:project) }

    let(:package) { build_stubbed(:generic_package) }

    it 'publishes an event' do
      expect { package.publish_creation_event }
        .to publish_event(::Packages::PackageCreatedEvent)
              .with({
                project_id: package.project_id,
                id: package.id,
                name: package.name,
                version: package.version,
                package_type: package.package_type
              })
    end
  end

  describe 'inheritance' do
    let_it_be(:project) { create(:project) }

    let(:format) { "" }
    let(:package) { create("#{format}_package", project: project) }
    let(:package_id) { package.id }

    subject { described_class.find_by(id: package_id).class }

    described_class
      .package_types
      .keys
      .map(&:to_sym)
      .each do |package_format|
      if described_class.inheritance_column_to_class_map[package_format].nil?
        context "for package format #{package_format}" do
          let(:format) { package_format }

          it 'maps to Packages::Package' do
            is_expected.to eq(described_class)
          end
        end
      else
        context "for package format #{package_format}" do
          let(:format) { package_format }

          it 'maps to the correct class' do
            is_expected.to eq(described_class.inheritance_column_to_class_map[package_format].constantize)
          end
        end
      end
    end
  end
end
