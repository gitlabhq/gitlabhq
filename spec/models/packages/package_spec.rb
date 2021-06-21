# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Package, type: :model do
  include SortingHelper

  it_behaves_like 'having unique enum values'

  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:creator) }
    it { is_expected.to have_many(:package_files).dependent(:destroy) }
    it { is_expected.to have_many(:dependency_links).inverse_of(:package) }
    it { is_expected.to have_many(:tags).inverse_of(:package) }
    it { is_expected.to have_many(:build_infos).inverse_of(:package) }
    it { is_expected.to have_many(:pipelines).through(:build_infos) }
    it { is_expected.to have_one(:conan_metadatum).inverse_of(:package) }
    it { is_expected.to have_one(:maven_metadatum).inverse_of(:package) }
    it { is_expected.to have_one(:debian_publication).inverse_of(:package).class_name('Packages::Debian::Publication') }
    it { is_expected.to have_one(:debian_distribution).through(:debian_publication).source(:distribution).inverse_of(:packages).class_name('Packages::Debian::ProjectDistribution') }
    it { is_expected.to have_one(:nuget_metadatum).inverse_of(:package) }
    it { is_expected.to have_one(:rubygems_metadatum).inverse_of(:package) }
  end

  describe '.with_debian_codename' do
    let_it_be(:publication) { create(:debian_publication) }

    subject { described_class.with_debian_codename(publication.distribution.codename).to_a }

    it { is_expected.to contain_exactly(publication.package) }
  end

  describe '.with_composer_target' do
    let!(:package1) { create(:composer_package, :with_metadatum, sha: '123') }
    let!(:package2) { create(:composer_package, :with_metadatum, sha: '123') }
    let!(:package3) { create(:composer_package, :with_metadatum, sha: '234') }

    subject { described_class.with_composer_target('123').to_a }

    it 'selects packages with the specified sha' do
      expect(subject).to include(package1)
      expect(subject).to include(package2)
      expect(subject).not_to include(package3)
    end
  end

  describe '.sort_by_attribute' do
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:project) { create(:project, :public, namespace: group, name: 'project A') }

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

      context "sorting by #{order_by}" do
        context 'ascending order' do
          let(:sort) { 'asc' }

          it { is_expected.to eq packages }
        end

        context 'descending order' do
          let(:sort) { 'desc' }

          it { is_expected.to eq packages.reverse }
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
      let(:another_project) { create(:project, :public, namespace: group, name: 'project B') }
      let!(:package4) { create(:npm_package, project: another_project, version: '3.1.0', name: "@#{project.root_namespace.path}/bar") }

      let(:packages) { [package1, package2, package3, package4] }
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

      context 'conan package' do
        subject { build_stubbed(:conan_package) }

        let(:fifty_one_characters) {'f_b' * 17}

        it { is_expected.to allow_value('foo+bar').for(:name) }
        it { is_expected.to allow_value('foo_bar').for(:name) }
        it { is_expected.to allow_value('foo.bar').for(:name) }
        it { is_expected.not_to allow_value(fifty_one_characters).for(:name) }
        it { is_expected.not_to allow_value('+foobar').for(:name) }
        it { is_expected.not_to allow_value('.foobar').for(:name) }
        it { is_expected.not_to allow_value('%foo%bar').for(:name) }
      end

      context 'debian package' do
        subject { build(:debian_package) }

        it { is_expected.to allow_value('0ad').for(:name) }
        it { is_expected.to allow_value('g++').for(:name) }
        it { is_expected.not_to allow_value('a_b').for(:name) }
      end

      context 'debian incoming' do
        subject { create(:debian_incoming) }

        # Only 'incoming' is accepted
        it { is_expected.to allow_value('incoming').for(:name) }
        it { is_expected.not_to allow_value('0ad').for(:name) }
        it { is_expected.not_to allow_value('g++').for(:name) }
        it { is_expected.not_to allow_value('a_b').for(:name) }
      end

      context 'generic package' do
        subject { build_stubbed(:generic_package) }

        it { is_expected.to allow_value('123').for(:name) }
        it { is_expected.to allow_value('foo').for(:name) }
        it { is_expected.to allow_value('foo.bar.baz-2.0-20190901.47283-1').for(:name) }
        it { is_expected.not_to allow_value('../../foo').for(:name) }
        it { is_expected.not_to allow_value('..\..\foo').for(:name) }
        it { is_expected.not_to allow_value('%2f%2e%2e%2f%2essh%2fauthorized_keys').for(:name) }
        it { is_expected.not_to allow_value('$foo/bar').for(:name) }
        it { is_expected.not_to allow_value('my file name').for(:name) }
        it { is_expected.not_to allow_value('!!().for(:name)().for(:name)').for(:name) }
      end

      context 'helm package' do
        subject { build(:helm_package) }

        it { is_expected.to allow_value('prometheus').for(:name) }
        it { is_expected.to allow_value('rook-ceph').for(:name) }
        it { is_expected.not_to allow_value('a+b').for(:name) }
        it { is_expected.not_to allow_value('Hé').for(:name) }
      end

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
      RSpec.shared_examples 'validating version to be SemVer compliant for' do |factory_name|
        context "for #{factory_name}" do
          subject { build_stubbed(factory_name) }

          it { is_expected.to allow_value('1.2.3').for(:version) }
          it { is_expected.to allow_value('1.2.3-beta').for(:version) }
          it { is_expected.to allow_value('1.2.3-alpha.3').for(:version) }
          it { is_expected.not_to allow_value('1').for(:version) }
          it { is_expected.not_to allow_value('1.2').for(:version) }
          it { is_expected.not_to allow_value('1./2.3').for(:version) }
          it { is_expected.not_to allow_value('../../../../../1.2.3').for(:version) }
          it { is_expected.not_to allow_value('%2e%2e%2f1.2.3').for(:version) }
        end
      end

      context 'conan package' do
        subject { build_stubbed(:conan_package) }

        let(:fifty_one_characters) {'1.2' * 17}

        it { is_expected.to allow_value('1.2').for(:version) }
        it { is_expected.to allow_value('1.2.3-beta').for(:version) }
        it { is_expected.to allow_value('1.2.3-pre1+build2').for(:version) }
        it { is_expected.not_to allow_value('1').for(:version) }
        it { is_expected.not_to allow_value(fifty_one_characters).for(:version) }
        it { is_expected.not_to allow_value('1./2.3').for(:version) }
        it { is_expected.not_to allow_value('.1.2.3').for(:version) }
        it { is_expected.not_to allow_value('+1.2.3').for(:version) }
        it { is_expected.not_to allow_value('%2e%2e%2f1.2.3').for(:version) }
      end

      context 'composer package' do
        it_behaves_like 'validating version to be SemVer compliant for', :composer_package

        it { is_expected.to allow_value('dev-master').for(:version) }
        it { is_expected.to allow_value('2.x-dev').for(:version) }
      end

      context 'debian package' do
        subject { build(:debian_package) }

        it { is_expected.to allow_value('2:4.9.5+dfsg-5+deb10u1').for(:version) }
        it { is_expected.not_to allow_value('1_0').for(:version) }
      end

      context 'debian incoming' do
        subject { create(:debian_incoming) }

        it { is_expected.to allow_value(nil).for(:version) }
        it { is_expected.not_to allow_value('2:4.9.5+dfsg-5+deb10u1').for(:version) }
        it { is_expected.not_to allow_value('1_0').for(:version) }
      end

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
        it { is_expected.to allow_value('1.2.3..beta').for(:version) }
        it { is_expected.to allow_value('1.2.3-beta').for(:version) }
        it { is_expected.to allow_value('10.2.3-beta').for(:version) }
        it { is_expected.to allow_value('2.0.0.v200706041905-7C78EK9E_EkMNfNOd2d8qq').for(:version) }
        it { is_expected.to allow_value('1.2-alpha-1-20050205.060708-1').for(:version) }
        it { is_expected.to allow_value('703220b4e2cea9592caeb9f3013f6b1e5335c293').for(:version) }
        it { is_expected.to allow_value('RELEASE').for(:version) }
        it { is_expected.not_to allow_value('..1.2.3').for(:version) }
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

      context 'generic package' do
        subject { build_stubbed(:generic_package) }

        it { is_expected.to validate_presence_of(:version) }
        it { is_expected.to allow_value('1.2.3').for(:version) }
        it { is_expected.to allow_value('1.3.350').for(:version) }
        it { is_expected.to allow_value('1.3.350-20201230123456').for(:version) }
        it { is_expected.to allow_value('1.2.3-rc1').for(:version) }
        it { is_expected.to allow_value('1.2.3g').for(:version) }
        it { is_expected.to allow_value('1.2').for(:version) }
        it { is_expected.to allow_value('1.2.bananas').for(:version) }
        it { is_expected.to allow_value('v1.2.4-build').for(:version) }
        it { is_expected.to allow_value('d50d836eb3de6177ce6c7a5482f27f9c2c84b672').for(:version) }
        it { is_expected.to allow_value('this_is_a_string_only').for(:version) }
        it { is_expected.not_to allow_value('..1.2.3').for(:version) }
        it { is_expected.not_to allow_value('  1.2.3').for(:version) }
        it { is_expected.not_to allow_value("1.2.3  \r\t").for(:version) }
        it { is_expected.not_to allow_value("\r\t 1.2.3").for(:version) }
        it { is_expected.not_to allow_value('1.2.3-4/../../').for(:version) }
        it { is_expected.not_to allow_value('1.2.3-4%2e%2e%').for(:version) }
        it { is_expected.not_to allow_value('../../../../../1.2.3').for(:version) }
        it { is_expected.not_to allow_value('%2e%2e%2f1.2.3').for(:version) }
        it { is_expected.not_to allow_value('').for(:version) }
        it { is_expected.not_to allow_value(nil).for(:version) }
      end

      context 'helm package' do
        subject { build_stubbed(:helm_package) }

        it { is_expected.not_to allow_value(nil).for(:version) }
        it { is_expected.not_to allow_value('').for(:version) }
        it { is_expected.to allow_value('v1.2.3').for(:version) }
        it { is_expected.to allow_value('1.2.3').for(:version) }
        it { is_expected.not_to allow_value('v1.2').for(:version) }
      end

      it_behaves_like 'validating version to be SemVer compliant for', :npm_package
      it_behaves_like 'validating version to be SemVer compliant for', :terraform_module_package

      context 'nuget package' do
        it_behaves_like 'validating version to be SemVer compliant for', :nuget_package

        it { is_expected.to allow_value('1.2.3.4').for(:version) }
      end
    end

    describe '#package_already_taken' do
      context 'maven package' do
        let!(:package) { create(:maven_package) }

        it 'will allow a package of the same name' do
          new_package = build(:maven_package, name: package.name)

          expect(new_package).to be_valid
        end
      end
    end

    context "recipe uniqueness for conan packages" do
      let!(:package) { create('conan_package') }

      it "will allow a conan package with same project, name, version and package_type" do
        new_package = build('conan_package', project: package.project, name: package.name, version: package.version)
        new_package.conan_metadatum.package_channel = 'beta'
        expect(new_package).to be_valid
      end

      it "will not allow a conan package with same recipe (name, version, metadatum.package_channel, metadatum.package_username, and package_type)" do
        new_package = build('conan_package', project: package.project, name: package.name, version: package.version)
        expect(new_package).not_to be_valid
        expect(new_package.errors.to_a).to include("Package recipe already exists")
      end
    end

    describe "#unique_debian_package_name" do
      let!(:package) { create(:debian_package) }

      it "will allow a Debian package with same project, name and version, but different distribution" do
        new_package = build(:debian_package, project: package.project, name: package.name, version: package.version)
        expect(new_package).to be_valid
      end

      it "will not allow a Debian package with same project, name, version and distribution" do
        new_package = build(:debian_package, project: package.project, name: package.name, version: package.version)
        new_package.debian_publication.distribution = package.debian_publication.distribution
        expect(new_package).not_to be_valid
        expect(new_package.errors.to_a).to include('Debian package already exists in Distribution')
      end

      it "will allow a Debian package with same project, name, version, but no distribution" do
        new_package = build(:debian_package, project: package.project, name: package.name, version: package.version, published_in: nil)
        expect(new_package).to be_valid
      end
    end

    Packages::Package.package_types.keys.without('conan', 'debian').each do |pt|
      context "project id, name, version and package type uniqueness for package type #{pt}" do
        let(:package) { create("#{pt}_package") }

        it "will not allow a #{pt} package with same project, name, version and package_type" do
          new_package = build("#{pt}_package", project: package.project, name: package.name, version: package.version)
          expect(new_package).not_to be_valid
          expect(new_package.errors.to_a).to include("Name has already been taken")
        end
      end
    end
  end

  describe '#destroy' do
    let(:package) { create(:npm_package) }
    let(:package_file) { package.package_files.first }
    let(:project_statistics) { ProjectStatistics.for_project_ids(package.project.id).first }

    it 'affects project statistics' do
      expect { package.destroy! }
        .to change { project_statistics.reload.packages_size }
              .from(package_file.size).to(0)
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

    describe '.last_of_each_version' do
      subject { described_class.last_of_each_version }

      it 'includes only latest package per version' do
        is_expected.to include(package1, package3)
        is_expected.not_to include(package2)
      end
    end

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

  context 'conan scopes' do
    let!(:package) { create(:conan_package) }

    describe '.with_conan_channel' do
      subject { described_class.with_conan_channel('stable') }

      it 'includes only packages with specified version' do
        is_expected.to include(package)
      end
    end

    describe '.with_conan_username' do
      subject do
        described_class.with_conan_username(
          Packages::Conan::Metadatum.package_username_from(full_path: package.project.full_path)
        )
      end

      it 'includes only packages with specified version' do
        is_expected.to match_array([package])
      end
    end
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

    context 'status scopes' do
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
        subject { described_class.installable }

        it 'does not include non-displayable packages', :aggregate_failures do
          is_expected.not_to include(error_package)
          is_expected.not_to include(hidden_package)
          is_expected.not_to include(processing_package)
        end
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
    let_it_be(:project) { create(:project, name: 'aaa' ) }
    let_it_be(:project2) { create(:project, name: 'bbb' ) }
    let_it_be(:package1) { create(:package, project: project ) }
    let_it_be(:package2) { create(:package, project: project2 ) }
    let_it_be(:package3) { create(:package, project: project2 ) }
    let_it_be(:package4) { create(:package, project: project ) }

    it 'orders packages by their projects name ascending' do
      expect(Packages::Package.order_project_name).to eq([package1, package4, package2, package3])
    end

    it 'orders packages by their projects name descending' do
      expect(Packages::Package.order_project_name_desc).to eq([package2, package3, package1, package4])
    end

    shared_examples 'order_project_path scope' do
      it 'orders packages by their projects path asc, then package id asc' do
        expect(Packages::Package.order_project_path).to eq([package1, package4, package2, package3])
      end
    end

    shared_examples 'order_project_path_desc scope' do
      it 'orders packages by their projects path desc, then package id desc' do
        expect(Packages::Package.order_project_path_desc).to eq([package3, package2, package4, package1])
      end
    end

    it_behaves_like 'order_project_path scope'
    it_behaves_like 'order_project_path_desc scope'
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

  describe '.keyset_pagination_order' do
    let(:join_class) { nil }
    let(:column_name) { nil }
    let(:direction) { nil }

    subject { described_class.keyset_pagination_order(join_class: join_class, column_name: column_name, direction: direction) }

    it { expect { subject }.to raise_error(NoMethodError) }

    context 'with valid params' do
      let(:join_class) { Project }
      let(:column_name) { :name }

      context 'ascending direction' do
        let(:direction) { :asc }

        it { is_expected.to eq('projects.name asc NULLS LAST, "packages_packages"."id" ASC') }
      end

      context 'descending direction' do
        let(:direction) { :desc }

        it { is_expected.to eq('projects.name desc NULLS FIRST, "packages_packages"."id" DESC') }
      end
    end
  end

  describe '#versions' do
    let_it_be(:project) { create(:project) }
    let_it_be(:package) { create(:maven_package, project: project) }
    let_it_be(:package2) { create(:maven_package, project: project) }
    let_it_be(:package3) { create(:maven_package, project: project, name: 'foo') }

    it 'returns other package versions of the same package name belonging to the project' do
      expect(package.versions).to contain_exactly(package2)
    end

    it 'does not return different packages' do
      expect(package.versions).not_to include(package3)
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

  describe '#tag_names' do
    let_it_be(:package) { create(:nuget_package) }

    subject { package.tag_names }

    it { is_expected.to eq([]) }

    context 'with tags' do
      let(:tags) { %w(tag1 tag2 tag3) }

      before do
        tags.each { |t| create(:packages_tag, name: t, package: package) }
      end

      it { is_expected.to contain_exactly(*tags) }
    end
  end

  describe '#debian_incoming?' do
    let(:package) { build(:package) }

    subject { package.debian_incoming? }

    it { is_expected.to eq(false) }

    context 'with debian_incoming' do
      let(:package) { create(:debian_incoming) }

      it { is_expected.to eq(true) }
    end

    context 'with debian_package' do
      let(:package) { create(:debian_package) }

      it { is_expected.to eq(false) }
    end
  end

  describe '#debian_package?' do
    let(:package) { build(:package) }

    subject { package.debian_package? }

    it { is_expected.to eq(false) }

    context 'with debian_incoming' do
      let(:package) { create(:debian_incoming) }

      it { is_expected.to eq(false) }
    end

    context 'with debian_package' do
      let(:package) { create(:debian_package) }

      it { is_expected.to eq(true) }
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
            .not_to raise_error(NoMethodError)
        end
      end
    end
  end

  describe '#original_build_info' do
    let_it_be_with_refind(:package) { create(:npm_package) }

    context 'without build_infos' do
      it 'returns nil' do
        expect(package.original_build_info).to be_nil
      end
    end

    context 'with build_infos' do
      let_it_be(:first_build_info) { create(:package_build_info, :with_pipeline, package: package) }
      let_it_be(:second_build_info) { create(:package_build_info, :with_pipeline, package: package) }

      it 'returns the first build info' do
        expect(package.original_build_info).to eq(first_build_info)
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
end
