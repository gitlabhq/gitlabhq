# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Package, feature_category: :package_registry do
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
  end

  describe '.sort_by_attribute' do
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:project) { create(:project, :public, namespace: group, name: 'project A', path: 'project-a') }

    let!(:package1) do
      create(:npm_package, project: project, version: '3.1.0', name: "@#{project.root_namespace.path}/foo1")
    end

    let!(:package2) { create(:nuget_package, project: project, version: '2.0.4') }
    let(:package3) { create(:maven_package, project: project, version: '1.1.1', name: 'zzz') }

    before do
      travel_to(1.day.ago) do
        package3
      end
    end

    RSpec.shared_examples 'package sorting by attribute' do |order_by|
      subject { described_class.where(id: packages.map(&:id)).sort_by_attribute("#{order_by}_#{sort}") }

      let(:packages_desc) { packages.reverse }

      context "when sorting by #{order_by}" do
        context 'for ascending order' do
          let(:sort) { 'asc' }

          it { is_expected.to eq packages }
        end

        context 'for descending order' do
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

    it_behaves_like 'package sorting by attribute', 'project_name' do
      let_it_be(:another_project) { create(:project, :public, namespace: group, name: 'project B') }
      let_it_be(:package4) { create(:generic_package, project: another_project) }

      let(:packages) { [package1, package4] }
    end

    it_behaves_like 'package sorting by attribute', 'project_path' do
      let_it_be(:another_project) { create(:project, :public, namespace: group, name: 'project B', path: 'project-b') }
      let_it_be(:package4) do
        create(:npm_package, project: another_project, version: '3.1.0', name: "@#{project.root_namespace.path}/bar")
      end

      let(:packages) { [package3, package2, package1, package4] }
      let(:packages_desc) { [package4, package3, package2, package1] }
    end
  end

  describe '.for_projects' do
    let_it_be(:package1) { create(:maven_package) }
    let_it_be(:package2) { create(:maven_package) }
    let_it_be(:package3) { create(:maven_package) }

    let(:projects) { ::Project.id_in([package1.project_id, package2.project_id]) }

    subject(:for_projects) { described_class.for_projects(projects.select(:id)) }

    it 'returns package1 and package2' do
      expect(for_projects).to match_array([package1, package2])
    end
  end

  describe 'validations' do
    subject { build(:maven_package) }

    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:project_id, :version, :package_type) }

    Packages::Package.package_types.keys.without('conan').each do |pt|
      context "for project id, name, version and package type uniqueness for package type #{pt}" do
        let(:package) { create("#{pt}_package") }

        it "does not allow a #{pt} package with same project, name, version and package_type" do
          new_package = build("#{pt}_package", project: package.project, name: package.name, version: package.version)
          expect(new_package).not_to be_valid
          expect(new_package.errors.to_a).to include("Name has already been taken")
        end

        context 'with pending_destruction package' do
          let!(:package) { create("#{pt}_package", :pending_destruction) }

          it "allows a #{pt} package with same project, name, version and package_type" do
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
      expect(project_statistics).to receive(:increment_counter)
        .with(:packages_size, have_attributes(amount: -package_file.size))

      destroy!
    end
  end

  describe '.by_name_and_file_name' do
    let!(:package) { create(:npm_package) }
    let!(:package_file) { package.package_files.first }

    it 'finds a package with correct arguments' do
      expect(described_class.by_name_and_file_name(package.name, package_file.file_name)).to eq(package)
    end

    it 'raises error if not found' do
      expect do
        described_class.by_name_and_file_name('foo', 'foo-5.5.5.tgz')
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  # TODO: Remove with the rollout of the FF packages_refactor_group_packages_finder
  # https://gitlab.com/gitlab-org/gitlab/-/issues/568923
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

  context 'for version scopes' do
    let_it_be(:package1) { create(:npm_package, version: '1.0.0') }
    let_it_be(:package2) { create(:npm_package, version: '1.0.1') }
    let_it_be(:package3) { create(:npm_package, version: '1.0.1') }

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

    describe '.with_version_like' do
      let(:version_pattern) { '%.0.1%' }

      subject { described_class.with_version_like(version_pattern) }

      it 'includes packages with the version pattern' do
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
      where(:name_term, :case_sensitive, :result) do
        'foobar' | false | [ref(:package1), ref(:package2)]
        '%ar'    | false | [ref(:package1), ref(:package2)]
        'foo%'   | false | [ref(:package1), ref(:package2)]
        '%ooba%' | false | [ref(:package1), ref(:package2)]

        'foobar' | true  | [ref(:package2)]
        '%ar'    | true  | [ref(:package1), ref(:package2)]
        '%Bar'   | true  | [ref(:package1)]
        'foo%'   | true  | [ref(:package2)]
        '%ooba%' | true  | [ref(:package2)]
        '%ooBa%' | true  | [ref(:package1)]
        'Foo%'   | true  | [ref(:package1)]
      end

      with_them do
        subject { described_class.with_name_like(name_term, case_sensitive:) }

        it { is_expected.to match_array(result) }
      end

      context 'when case_sensitive is not set' do
        subject { described_class.with_name_like('foobar') }

        it { is_expected.to match_array([package1, package2]) }
      end
    end

    describe '.search_by_name' do
      let(:query) { 'oba' }

      subject { described_class.search_by_name(query) }

      it { is_expected.to match_array([package1, package2]) }
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

    context 'for status scopes' do
      let_it_be(:default_package) { create(:maven_package, :default) }
      let_it_be(:hidden_package) { create(:maven_package, :hidden) }
      let_it_be(:processing_package) { create(:maven_package, :processing) }
      let_it_be(:error_package) { create(:maven_package, :error) }
      let_it_be(:deprecated_package) { create(:maven_package, :deprecated) }

      describe '.displayable' do
        subject { described_class.displayable }

        it 'does not include non-displayable packages', :aggregate_failures do
          is_expected.to include(error_package)
          is_expected.to include(deprecated_package)
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
    let_it_be(:nuget_packages) do
      create_list(:nuget_package, 3, name: nuget_package.name, project: nuget_package.project)
    end

    let_it_be(:maven_package) { create(:maven_package) }
    let_it_be(:maven_packages) do
      create_list(:maven_package, 3, name: maven_package.name, project: maven_package.project)
    end

    subject(:packages) { described_class.select_distinct_name }

    it 'returns only distinct names' do
      expect(packages.size).to eq(2)
      expect(packages.pluck(:name)).to match_array([nuget_package.name, maven_package.name])
    end
  end

  context 'for sorting' do
    let_it_be(:project) { create(:project, path: 'aaa') }
    let_it_be(:project2) { create(:project, path: 'bbb') }
    let_it_be(:package1) { create(:generic_package, project: project) }
    let_it_be(:package2) { create(:generic_package, project: project2) }

    it 'orders packages by their projects name ascending' do
      expect(described_class.order_project_name).to eq([package1, package2])
    end

    it 'orders packages by their projects name descending' do
      expect(described_class.order_project_name_desc).to eq([package2, package1])
    end

    context 'with additional packages' do
      let_it_be(:package3) { create(:generic_package, project: project2) }
      let_it_be(:package4) { create(:generic_package, project: project) }

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
      expect(::Packages::Maven::Package.for_projects(project).order_by_package_file).to match_array(
        [package1, package1, package1, package2, package2, package2]
      )

      create(:package_file, :xml, package: package1)

      expect(::Packages::Maven::Package.for_projects(project).order_by_package_file).to match_array(
        [package1, package1, package1, package2, package2, package2, package1]
      )
    end
  end

  describe '.preload_tags' do
    let_it_be(:package) { create(:npm_package) }
    let_it_be(:tags) { create_list(:packages_tag, 2, package: package) }

    subject(:packages) { described_class.preload_tags }

    it 'preloads tags' do
      expect(packages.first.association(:tags)).to be_loaded
    end
  end

  describe '.preload_project' do
    let_it_be(:project) { create(:project) }
    let_it_be(:package) { create_list(:npm_package, 2, project: project) }

    subject(:packages) { described_class.preload_project }

    it 'preloads project' do
      expect(packages.first.association(:project)).to be_loaded
    end
  end

  describe '.preload_pipelines_with_user_project_namespace_route' do
    let_it_be(:project) { create(:project) }

    let_it_be(:package) do
      create(:generic_package, pipelines: [create(:ci_pipeline, project: project)], project: project)
    end

    subject(:execute) { described_class.preload_pipelines_with_user_project_namespace_route.id_in(package.id) }

    it 'preloads pipelines with user, project, namespace and route' do
      record = execute.first
      pipeline = record.pipelines.first

      expect(record.association(:pipelines)).to be_loaded
      expect(pipeline.association(:user)).to be_loaded
      expect(pipeline.association(:project)).to be_loaded
      expect(pipeline.project.association(:namespace)).to be_loaded
      expect(pipeline.project.namespace.association(:route)).to be_loaded
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

    context 'for package without pipeline' do
      it 'returns nil if there is no pipeline' do
        expect(package.pipeline).to be_nil
      end
    end

    context 'for package with pipeline' do
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

    context 'for package without pipeline' do
      it { is_expected.to be_empty }
    end

    context 'for package with pipeline' do
      let_it_be(:pipeline) { create(:ci_pipeline) }
      let_it_be(:pipeline2) { create(:ci_pipeline) }

      before do
        package.build_infos.create!(pipeline: pipeline)
        package.build_infos.create!(pipeline: pipeline2)
      end

      it { is_expected.to contain_exactly(pipeline, pipeline2) }
    end
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

      it { is_expected.to match_array(tags) }
    end
  end

  describe 'plan_limits' do
    Packages::Package.package_types.keys.without('composer').each do |pt|
      plan_limit_name = if pt == 'generic'
                          "#{pt}_packages_max_file_size"
                        else
                          "#{pt}_max_file_size"
                        end

      context "with file size limits for #{pt}" do
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

  describe '#mark_package_files_for_destruction' do
    let_it_be(:package) { create(:npm_package, :pending_destruction) }

    subject(:mark_package_files_for_destruction) { package.mark_package_files_for_destruction }

    it 'enqueues a sync worker job' do
      expect(::Packages::MarkPackageFilesForDestructionWorker)
        .to receive(:perform_async).with(package.id)

      mark_package_files_for_destruction
    end

    context 'for a package non pending destruction' do
      let_it_be(:package) { create(:npm_package) }

      it 'does not enqueues a sync worker job' do
        expect(::Packages::MarkPackageFilesForDestructionWorker)
        .not_to receive(:perform_async).with(package.id)

        mark_package_files_for_destruction
      end
    end
  end

  describe '#create_build_infos!' do
    let_it_be(:package) { create(:generic_package) }
    let_it_be(:pipeline) { create(:ci_pipeline) }

    let(:build) { instance_double(Ci::Build, pipeline:) }

    subject(:create_build_infos) { package.create_build_infos!(build) }

    context 'with a valid build' do
      it 'creates a build info' do
        expect { create_build_infos }.to change { ::Packages::BuildInfo.count }.by(1)

        last_build = ::Packages::BuildInfo.last
        expect(last_build.package).to eq(package)
        expect(last_build.pipeline).to eq(pipeline)
      end

      context 'with an already existing build info' do
        let_it_be(:build_info) { create(:package_build_info, package: package, pipeline: pipeline) }

        it 'does not create a build info' do
          expect { create_build_infos }.not_to change { ::Packages::BuildInfo.count }
        end
      end
    end

    context 'with a nil build' do
      let(:build) { nil }

      it 'does not create a build info' do
        expect { create_build_infos }.not_to change { ::Packages::BuildInfo.count }
      end
    end

    context 'with a build without a pipeline' do
      let(:build) { instance_double(Ci::Build, pipeline: nil) }

      it 'does not create a build info' do
        expect { create_build_infos }.not_to change { ::Packages::BuildInfo.count }
      end
    end
  end

  context 'with identical pending destruction package' do
    described_class.package_types.each_key do |package_format|
      context "for package format #{package_format}" do
        let_it_be(:package_pending_destruction) { create("#{package_format}_package", :pending_destruction) }

        let(:new_package) do
          build(
            "#{package_format}_package",
            name: package_pending_destruction.name,
            version: package_pending_destruction.version,
            project: package_pending_destruction.project
          )
        end

        it { expect(new_package).to be_valid }
      end
    end
  end

  describe '#publish_creation_event' do
    let_it_be(:project) { create(:project) }

    let(:package) { build_stubbed(:ml_model_package) }

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

  describe '#detailed_info?' do
    subject { package.detailed_info? }

    where(:status, :result) do
      :default             | true
      :deprecated          | true
      :hidden              | false
      :processing          | false
      :error               | false
      :pending_destruction | false
    end

    with_them do
      let(:package) { build(:maven_package, status: status) }

      it { is_expected.to eq(result) }
    end
  end
end
