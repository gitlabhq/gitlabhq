# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Npm::GenerateMetadataService, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:package_name) { "@#{project.root_namespace.path}/test" }
  let_it_be(:package1) { create(:npm_package, version: '2.0.4', project: project, name: package_name) }
  let_it_be(:package2) { create(:npm_package, version: '2.0.6', project: project, name: package_name) }
  let_it_be(:latest_package) { create(:npm_package, version: '2.0.11', project: project, name: package_name) }

  let(:packages) { ::Packages::Npm::Package.for_projects(project).with_name(package_name) }
  let(:metadata) { described_class.new(package_name, packages).execute }

  describe '#versions' do
    let_it_be(:version_schema) { 'public_api/v4/packages/npm_package_version' }
    let_it_be(:package_json) do
      {
        name: package_name,
        version: '2.0.4',
        deprecated: 'warning!',
        bin: './cli.js',
        directories: ['lib'],
        engines: { npm: '^7.5.6' },
        _hasShrinkwrap: false,
        hasInstallScript: true,
        dist: {
          tarball: 'http://localhost/tarball.tgz',
          shasum: '1234567890'
        },
        custom_field: 'foo_bar'
      }
    end

    subject { metadata[:versions] }

    where(:has_dependencies, :has_metadatum) do
      true  | true
      false | true
      true  | false
      false | false
    end

    with_them do
      if params[:has_dependencies]
        ::Packages::DependencyLink.dependency_types.each_key do |dependency_type| # rubocop:disable RSpec/UselessDynamicDefinition -- `dependency_type` used in `let_it_be`
          let_it_be("package_dependency_link_for_#{dependency_type}") do
            create(:packages_dependency_link, package: package1, dependency_type: dependency_type)
          end
        end
      end

      if params[:has_metadatum]
        let_it_be(:package_metadatadum) { create(:npm_metadatum, package: package1, package_json: package_json) }
      end

      it { is_expected.to be_a(Hash) }
      it { expect(subject[package1.version].with_indifferent_access).to match_schema(version_schema) }
      it { expect(subject[package2.version].with_indifferent_access).to match_schema(version_schema) }
      it { expect(subject[package1.version]['custom_field']).to be_blank }

      context 'for dependencies' do
        ::Packages::DependencyLink.dependency_types.each_key do |dependency_type|
          if params[:has_dependencies]
            it { expect(subject.dig(package1.version, dependency_type.to_s)).to be_any }
          else
            it { expect(subject.dig(package1.version, dependency_type)).to be nil }
          end

          it { expect(subject.dig(package2.version, dependency_type)).to be nil }
        end

        context 'when generate dependencies' do
          let(:packages) { ::Packages::Npm::Package.where(id: package1.id) }

          it 'loads grouped dependency links', :aggregate_failures do
            expect(::Packages::DependencyLink).to receive(:dependency_ids_grouped_by_type).and_call_original
            expect(::Packages::Package).not_to receive(:including_dependency_links)

            subject
          end
        end
      end

      context 'for metadatum' do
        ::Packages::Npm::GenerateMetadataService::PACKAGE_JSON_ALLOWED_FIELDS.each do |metadata_field|
          if params[:has_metadatum]
            it { expect(subject.dig(package1.version, metadata_field)).not_to be nil }
          else
            it { expect(subject.dig(package1.version, metadata_field)).to be nil }
          end

          it { expect(subject.dig(package2.version, metadata_field)).to be nil }
        end
      end

      it 'avoids N+1 database queries' do
        check_n_plus_one do
          create_list(:npm_package, 5, project: project, name: package_name).each do |npm_package|
            next unless has_dependencies

            ::Packages::DependencyLink.dependency_types.each_key do |dependency_type|
              create(:packages_dependency_link, package: npm_package, dependency_type: dependency_type)
            end
          end
        end
      end
    end

    context 'with package files pending destruction' do
      let_it_be(:package_file_pending_destruction) do
        create(:package_file, :pending_destruction, package: package2, file_sha1: 'pending_destruction_sha1')
      end

      let(:shasums) { subject.values.map { |v| v.dig(:dist, :shasum) } }

      it 'does not return them' do
        expect(shasums).not_to include(package_file_pending_destruction.file_sha1)
      end
    end
  end

  describe '#dist_tags' do
    subject { metadata[:dist_tags] }

    context 'for packages without tags' do
      it { is_expected.to be_a(Hash) }
      it { expect(subject['latest']).to eq(latest_package.version) }

      it 'avoids N+1 database queries' do
        check_n_plus_one(only_dist_tags: true) do
          create_list(:npm_package, 5, project: project, name: package_name)
        end
      end
    end

    context 'for packages with tags' do
      let_it_be(:package_tag1) { create(:packages_tag, package: package1, name: 'release_a') }
      let_it_be(:package_tag2) { create(:packages_tag, package: package1, name: 'test_release') }
      let_it_be(:package_tag3) { create(:packages_tag, package: package2, name: 'release_b') }
      let_it_be(:package_tag4) { create(:packages_tag, package: latest_package, name: 'release_c') }
      let_it_be(:package_tag5) { create(:packages_tag, package: latest_package, name: 'latest') }

      it { is_expected.to be_a(Hash) }
      it { expect(subject[package_tag1.name]).to eq(package1.version) }
      it { expect(subject[package_tag2.name]).to eq(package1.version) }
      it { expect(subject[package_tag3.name]).to eq(package2.version) }
      it { expect(subject[package_tag4.name]).to eq(latest_package.version) }
      it { expect(subject[package_tag5.name]).to eq(latest_package.version) }

      it 'avoids N+1 database queries' do
        check_n_plus_one(only_dist_tags: true) do
          create_list(:npm_package, 5, project: project, name: package_name).each_with_index do |npm_package, index|
            create(:packages_tag, package: npm_package, name: "tag_#{index}")
          end
        end
      end

      context 'with duplicate tags' do
        context 'when in different projects' do
          let_it_be(:project2) { create(:project, namespace: group) }
          let_it_be(:package2) { create(:npm_package, version: '3.0.0', project: project2, name: package_name) }
          let_it_be(:package_tag1) { create(:packages_tag, package: package1, name: 'latest') }
          let_it_be(:package_tag2) { create(:packages_tag, package: package2, name: 'latest') }

          let(:packages) { ::Packages::Npm::Package.for_projects([project.id, project2.id]).with_name(package_name) }

          it "returns the tag of the latest package's version" do
            expect(subject['latest']).to eq(package2.version)
          end
        end

        context 'when in the same project' do
          let_it_be(:package_a) { create(:npm_package, version: '1.2.3', project: project, name: package_name) }
          let_it_be(:package_b) { create(:npm_package, version: '1.1.1', project: project, name: package_name) }
          let_it_be(:package_tag_a) { create(:packages_tag, package: package_a, name: 'tag', updated_at: 1.week.ago) }
          let_it_be(:package_tag_b) { create(:packages_tag, package: package_b, name: 'tag') }

          it "returns the most recent tagged package's version" do
            expect(subject['tag']).to eq(package_b.version)
          end
        end
      end

      context 'when fetching all package tags' do
        let_it_be(:tags_limit) { 3 }

        before do
          stub_const('Packages::Tag::FOR_PACKAGES_TAGS_LIMIT', tags_limit)
        end

        it 'returns all tags' do
          expect(::Packages::Npm::Package).to receive(:preload_tags).and_call_original

          expect(subject.size).to eq(Packages::Tag.count)
        end
      end
    end
  end

  context 'when passing only_dist_tags: true' do
    subject { described_class.new(package_name, packages).execute(only_dist_tags: true) }

    it 'returns only dist tags' do
      expect(subject.payload.keys).to contain_exactly(:dist_tags)
    end
  end

  def check_n_plus_one(only_dist_tags: false)
    pkgs = ::Packages::Npm::Package.for_projects(project).with_name(package_name).preload_files
    control = ActiveRecord::QueryRecorder.new do
      described_class.new(package_name, pkgs).execute(only_dist_tags: only_dist_tags)
    end

    yield

    pkgs = ::Packages::Npm::Package.for_projects(project).with_name(package_name).preload_files

    expect do
      described_class.new(package_name, pkgs).execute(only_dist_tags: only_dist_tags)
    end.not_to exceed_query_limit(control)
  end
end
