# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::PackageFile, type: :model, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) }
  let_it_be(:package_file1) { create(:package_file, :xml, file_name: 'FooBar') }
  let_it_be(:package_file2) { create(:package_file, :xml, file_name: 'ThisIsATest') }
  let_it_be(:package_file3) { create(:package_file, :xml, file_name: 'formatted.zip') }
  let_it_be(:package_file4) { create(:package_file, :nuget, file_name: 'package-1.0.0.nupkg') }
  let_it_be(:package_file5) { create(:package_file, :xml, file_name: 'my_dir%2Fformatted') }
  let_it_be_with_reload(:debian_package) { create(:debian_package, project: project, with_changes_file: true) }

  it_behaves_like 'having unique enum values'
  it_behaves_like 'destructible', factory: :package_file

  describe 'relationships' do
    it { is_expected.to belong_to(:package) }
    it { is_expected.to have_one(:conan_file_metadatum) }
    it { is_expected.to have_many(:package_file_build_infos).inverse_of(:package_file) }
    it { is_expected.to have_one(:debian_file_metadatum).inverse_of(:package_file).class_name('Packages::Debian::FileMetadatum') }
    it { is_expected.to have_one(:helm_file_metadatum).inverse_of(:package_file).class_name('Packages::Helm::FileMetadatum') }
  end

  describe 'included modules' do
    it { is_expected.to include_module(AfterCommitQueue) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:package) }

    context 'with pypi package' do
      let_it_be(:package) { create(:pypi_package) }

      let(:package_file) { package.package_files.first }
      let(:status) { :default }
      let(:file_name) { 'foo' }
      let(:file) { fixture_file_upload('spec/fixtures/dk.png') }
      let(:params) { { file: file, file_name: file_name, status: status } }

      subject(:create_package_file) { package.package_files.create!(params) }

      context 'file_name' do
        let(:file_name) { package_file.file_name }

        it 'can not save a duplicated file' do
          expect { create_package_file }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: File name has already been taken")
        end

        context 'with a pending destruction package duplicated file' do
          let(:status) { :pending_destruction }

          it 'can save it' do
            expect { create_package_file }.to change { package.package_files.count }.from(1).to(2)
          end
        end
      end

      context 'file_sha256' do
        where(:sha256_value, :expected_success) do
          ('a' * 64) | true
          nil | true
          ('a' * 63)       | false
          ('a' * 65)       | false
          (('a' * 63) + '%') | false
          '' | false
        end

        with_them do
          let(:params) { super().merge({ file_sha256: sha256_value }) }

          it 'does not allow invalid sha256 characters' do
            if expected_success
              expect { create_package_file }.not_to raise_error
            else
              expect { create_package_file }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: File sha256 is invalid")
            end
          end
        end
      end
    end

    context 'with conan package' do
      let_it_be(:package) { create(:conan_package, without_package_files: true) }
      let_it_be(:recipe_revision) { package.conan_recipe_revisions.first }
      let_it_be(:package_reference) { package.conan_package_references.first }
      let_it_be(:package_revision) { package.conan_package_revisions.first }

      let_it_be_with_reload(:existing_file) do
        create(:conan_package_file, :conan_package, package: package, conan_recipe_revision: recipe_revision, conan_package_revision: package_revision)
      end

      context 'when creating a new file' do
        let(:new_file) do
          build(
            :conan_package_file,
            :conan_package,
            package: package,
            file_name: 'conan_package.tgz',
            conan_file_metadatum: build(
              :conan_file_metadatum,
              :package_file,
              recipe_revision: recipe_revision,
              package_reference: package_reference,
              package_revision: package_revision
            )
          )
        end

        it 'validates uniqueness of file name with same recipe revision, package reference and package revision' do
          expect(new_file).not_to be_valid
          expect(new_file.errors[:file_name]).to include('already exists for the given recipe revision, package reference, and package revision')
        end

        it 'allows same file name with different recipe revision' do
          new_file.conan_file_metadatum.recipe_revision = build_stubbed(:conan_recipe_revision, package: package)
          expect(new_file).to be_valid
        end

        it 'allows same file name with different package reference' do
          new_file.conan_file_metadatum.package_reference = build_stubbed(:conan_package_reference, package: package)
          expect(new_file).to be_valid
        end

        it 'allows same file name with different package revision' do
          new_file.conan_file_metadatum.package_revision = build_stubbed(:conan_package_revision, package: package)
          expect(new_file).to be_valid
        end

        it 'allows same file name without revision' do
          new_file.conan_file_metadatum.recipe_revision = nil
          new_file.conan_file_metadatum.package_revision = nil
          expect(new_file).to be_valid
        end

        context 'when existing file is not installable' do
          it 'allows same file name' do
            existing_file.update!(status: :pending_destruction)
            expect(new_file).to be_valid
          end
        end

        context 'when both existing and new files have no revision' do
          let_it_be(:recipe_revision) { nil }
          let_it_be(:package_revision) { nil }

          it 'allows same file name' do
            expect(new_file).to be_valid
          end
        end

        context 'when updating an existing file' do
          it 'does not validate uniqueness on update' do
            duplicate_file = create(
              :conan_package_file,
              :conan_package,
              package: package,
              file_name: 'duplicate_conan_package.tgz'
            )

            expect { existing_file.update!(file_name: duplicate_file.file_name) }.not_to raise_error
          end
        end
      end
    end
  end

  context 'with package filenames' do
    describe '.with_file_name' do
      let(:filename) { 'FooBar' }

      subject { described_class.with_file_name(filename) }

      it { is_expected.to match_array([package_file1]) }
    end

    describe '.with_file_name_like' do
      let(:filename) { 'foobar' }

      subject { described_class.with_file_name_like(filename) }

      it { is_expected.to match_array([package_file1]) }
    end

    describe '.with_format' do
      subject { described_class.with_format('zip') }

      it { is_expected.to contain_exactly(package_file3) }
    end

    describe '.with_nuget_format' do
      subject { described_class.with_nuget_format }

      it { is_expected.to contain_exactly(package_file4) }
    end
  end

  context 'updating project statistics' do
    let_it_be(:package, reload: true) { create(:maven_package, package_files: [], maven_metadatum: nil) }

    context 'when the package file has an explicit size' do
      subject { build(:package_file, :jar, package: package, size: 42) }

      it_behaves_like 'UpdateProjectStatistics', :packages_size
    end
  end

  describe '.for_package_ids' do
    it 'returns matching packages' do
      expect(described_class.for_package_ids([package_file1.package.id, package_file2.package.id]))
        .to contain_exactly(package_file1, package_file2)
    end
  end

  describe '.for_rubygem_with_file_name' do
    let_it_be(:non_ruby_package) { create(:nuget_package, project: project, package_type: :nuget) }
    let_it_be(:ruby_package) { create(:rubygems_package, project: project, package_type: :rubygems) }
    let_it_be(:file_name) { 'other.gem' }

    let_it_be(:non_ruby_file) { create(:package_file, :nuget, package: non_ruby_package, file_name: file_name) }
    let_it_be(:gem_file1) { create(:package_file, :gem, package: ruby_package) }
    let_it_be(:gem_file2) { create(:package_file, :gem, package: ruby_package, file_name: file_name) }

    it 'returns the matching gem file only for ruby packages' do
      expect(described_class.for_rubygem_with_file_name(project, file_name)).to contain_exactly(gem_file2)
    end
  end

  context 'Conan scopes' do
    let_it_be(:package) { create(:conan_package, without_package_files: true) }

    describe '.with_conan_package_reference' do
      let_it_be(:package_reference) { create(:conan_package_reference, package: package) }
      let_it_be(:other_package_reference) { create(:conan_package_reference, package: package) }

      let_it_be(:matching_package_file) do
        create(:conan_package_file, :conan_package,
          package: package,
          conan_package_reference: package_reference)
      end

      let_it_be(:package_file_with_other_reference) do
        create(:conan_package_file, :conan_package,
          package: package,
          conan_package_reference: other_package_reference)
      end

      subject(:result) { described_class.with_conan_package_reference(reference) }

      context 'with existing reference' do
        let(:reference) { matching_package_file.conan_file_metadatum.package_reference.reference }

        it 'returns package files with matching reference' do
          expect(result).to contain_exactly(matching_package_file)
        end
      end

      context 'when reference does not exist' do
        let(:reference) { non_existing_record_id.to_s }

        it 'returns empty relation' do
          expect(result).to be_empty
        end
      end
    end

    context 'recipe revision scopes' do
      let_it_be(:recipe_revision) { package.conan_recipe_revisions.first }
      let_it_be(:other_revision) { create(:conan_recipe_revision, package: package) }

      let_it_be(:package_file_with_revision) do
        create(:conan_package_file, :conan_recipe_file,
          package: package,
          conan_recipe_revision: recipe_revision)
      end

      let_it_be(:package_file_with_other_revision) do
        create(:conan_package_file, :conan_recipe_file,
          package: package,
          conan_recipe_revision: other_revision)
      end

      let_it_be(:package_file_without_revision) do
        create(:conan_package_file, :conan_recipe_file,
          package: package, conan_recipe_revision: nil)
      end

      describe '.with_conan_recipe_revision' do
        subject(:result) { described_class.with_conan_recipe_revision(revision) }

        context 'with existing revision' do
          let(:revision) { recipe_revision.revision }

          it 'returns package files with matching recipe revision' do
            expect(result).to contain_exactly(package_file_with_revision)
          end
        end

        context 'when revision does not exist' do
          let(:revision) { 'nonexistent' }

          it 'returns empty relation' do
            expect(result).to be_empty
          end
        end
      end

      describe '.without_conan_recipe_revision' do
        subject(:result) { described_class.without_conan_recipe_revision }

        it 'returns only package files without recipe revision' do
          expect(result).to contain_exactly(package_file_without_revision)
        end
      end
    end

    context 'package revision scopes' do
      let_it_be(:package_revision) { package.conan_package_revisions.first }
      let_it_be(:other_package_revision) { create(:conan_package_revision, package_reference: package.conan_package_references.first) }

      let_it_be(:package_file_with_revision) do
        create(:conan_package_file, :conan_package,
          package: package,
          conan_package_revision: package_revision)
      end

      let_it_be(:package_file_with_other_revision) do
        create(:conan_package_file, :conan_package,
          package: package,
          conan_package_revision: other_package_revision)
      end

      let_it_be(:package_file_without_revision) do
        create(:conan_package_file, :conan_package,
          package: package, conan_recipe_revision: nil, conan_package_revision: nil)
      end

      describe '.with_conan_package_revision' do
        subject(:result) { described_class.with_conan_package_revision(revision) }

        context 'with existing revision' do
          let(:revision) { package_revision.revision }

          it 'returns package files with matching package revision' do
            expect(result).to contain_exactly(package_file_with_revision)
          end
        end

        context 'when revision does not exist' do
          let(:revision) { 'nonexistent' }

          it 'returns empty relation' do
            expect(result).to be_empty
          end
        end
      end

      describe '.without_conan_package_revision' do
        subject(:result) { described_class.without_conan_package_revision }

        it 'returns only package files without package revision' do
          expect(result).to contain_exactly(package_file_without_revision)
        end
      end
    end
  end

  context 'Debian scopes' do
    let_it_be(:debian_changes) { debian_package.package_files.last }
    let_it_be(:debian_deb) { create(:debian_package_file, package: debian_package) }
    let_it_be(:debian_udeb) { create(:debian_package_file, :udeb, package: debian_package) }
    let_it_be(:debian_ddeb) { create(:debian_package_file, :ddeb, package: debian_package) }

    let_it_be(:debian_contrib) do
      create(:debian_package_file, package: debian_package).tap do |pf|
        pf.debian_file_metadatum.update!(component: 'contrib')
      end
    end

    let_it_be(:debian_mipsel) do
      create(:debian_package_file, package: debian_package).tap do |pf|
        pf.debian_file_metadatum.update!(architecture: 'mipsel')
      end
    end

    describe '#with_debian_file_type' do
      it { expect(described_class.with_debian_file_type(:changes)).to contain_exactly(debian_changes) }
    end

    describe '#with_debian_component_name' do
      it { expect(described_class.with_debian_component_name('contrib')).to contain_exactly(debian_contrib) }
    end

    describe '#with_debian_architecture_name' do
      it { expect(described_class.with_debian_architecture_name('mipsel')).to contain_exactly(debian_mipsel) }
    end

    describe '#with_debian_unknown_since' do
      let_it_be(:incoming) { create(:debian_incoming, project: project) }

      before do
        incoming.package_files.first.debian_file_metadatum.update! updated_at: 1.day.ago
        incoming.package_files.second.update! updated_at: 1.day.ago, status: :error
      end

      it { expect(described_class.with_debian_unknown_since(1.hour.ago)).to contain_exactly(incoming.package_files.first) }
    end
  end

  describe '.for_helm_with_channel' do
    let_it_be(:project) { create(:project) }
    let_it_be(:non_helm_package) { create(:nuget_package, project: project, package_type: :nuget) }
    let_it_be(:helm_package1) { create(:helm_package, project: project, package_type: :helm) }
    let_it_be(:helm_package2) { create(:helm_package, project: project, package_type: :helm) }
    let_it_be(:channel) { 'some-channel' }

    let_it_be(:non_helm_file) { create(:package_file, :nuget, package: non_helm_package) }
    let_it_be(:helm_file1) { create(:helm_package_file, package: helm_package1) }
    let_it_be(:helm_file2) { create(:helm_package_file, package: helm_package2, channel: channel) }

    it 'returns the matching file only for Helm packages' do
      expect(described_class.for_helm_with_channel(project, channel)).to contain_exactly(helm_file2)
    end

    context 'with package files pending destruction' do
      let_it_be(:package_file_pending_destruction) { create(:helm_package_file, :pending_destruction, package: helm_package2, channel: channel) }

      it 'does not return them' do
        expect(described_class.for_helm_with_channel(project, channel)).to contain_exactly(helm_file2)
      end
    end
  end

  describe '.most_recent!' do
    it { expect(described_class.most_recent!).to eq(debian_package.package_files.last) }
  end

  describe '.most_recent_for' do
    let_it_be(:package1) { create(:npm_package) }
    let_it_be(:package2) { create(:npm_package) }
    let_it_be(:package3) { create(:npm_package) }
    let_it_be(:package4) { create(:npm_package) }

    let_it_be(:package_file2_2) { create(:package_file, :npm, package: package2) }

    let_it_be(:package_file3_2) { create(:package_file, :npm, package: package3) }
    let_it_be(:package_file3_3) { create(:package_file, :npm, package: package3) }
    let_it_be(:package_file3_4) { create(:package_file, :npm, :pending_destruction, package: package3) }

    let_it_be(:package_file4_2) { create(:package_file, :npm, package: package2) }
    let_it_be(:package_file4_3) { create(:package_file, :npm, package: package2) }
    let_it_be(:package_file4_4) { create(:package_file, :npm, package: package2) }
    let_it_be(:package_file4_4) { create(:package_file, :npm, :pending_destruction, package: package2) }

    let(:most_recent_package_file1) { package1.installable_package_files.recent.first }
    let(:most_recent_package_file2) { package2.installable_package_files.recent.first }
    let(:most_recent_package_file3) { package3.installable_package_files.recent.first }
    let(:most_recent_package_file4) { package4.installable_package_files.recent.first }

    subject { described_class.most_recent_for(packages) }

    where(
      package_input1: [1, nil],
      package_input2: [2, nil],
      package_input3: [3, nil],
      package_input4: [4, nil]
    )

    with_them do
      let(:compact_inputs) { [package_input1, package_input2, package_input3, package_input4].compact }
      let(:packages) do
        ::Packages::Package.id_in(
          compact_inputs.map { |pkg_number| public_send("package#{pkg_number}") }
            .map(&:id)
        )
      end

      let(:expected_package_files) { compact_inputs.map { |pkg_number| public_send("most_recent_package_file#{pkg_number}") } }

      it { is_expected.to contain_exactly(*expected_package_files) }
    end

    describe '.order_by' do
      let_it_be(:package) { create(:generic_package, project:) }
      let_it_be(:older_file) { create(:package_file, package: package, file_name: 'beta.txt', created_at: 2.days.ago) }
      let_it_be(:newer_file) { create(:package_file, package: package, file_name: 'alpha.txt', created_at: 1.day.ago) }

      where(:column_name, :order, :expected_order) do
        'id'         | 'asc'     | ->(older, newer) { [older, newer] }
        'id'         | 'desc'    | ->(older, newer) { [newer, older] }
        'file_name'  | 'asc'     | ->(older, newer) { [newer, older] }
        'file_name'  | 'desc'    | ->(older, newer) { [older, newer] }
        'created_at' | 'asc'     | ->(older, newer) { [older, newer] }
        'created_at' | 'desc'    | ->(older, newer) { [newer, older] }
        'invalid'    | 'asc'     | nil
        'id'         | 'invalid' | nil
      end

      with_them do
        subject(:ordered_files) { described_class.where(package:).order_by(column_name, order) }

        it 'returns the package files in the expected order' do
          if expected_order
            expect(ordered_files.first(2)).to eq(expected_order.call(older_file, newer_file))
          else
            expect(ordered_files.order_values).to be_empty
          end
        end
      end
    end

    context 'extra join and extra where' do
      let_it_be(:helm_package) { create(:helm_package, without_package_files: true) }
      let_it_be(:helm_package_file1) { create(:helm_package_file, channel: 'alpha') }
      let_it_be(:helm_package_file2) { create(:helm_package_file, channel: 'alpha', package: helm_package) }
      let_it_be(:helm_package_file3) { create(:helm_package_file, channel: 'beta', package: helm_package) }
      let_it_be(:helm_package_file4) { create(:helm_package_file, channel: 'beta', package: helm_package) }

      let(:extra_join) { :helm_file_metadatum }
      let(:extra_where) { { packages_helm_file_metadata: { channel: 'alpha' } } }

      subject(:joined_result) { described_class.most_recent_for(Packages::Package.id_in(helm_package.id), extra_join: extra_join, extra_where: extra_where) }

      it 'returns the most recent package for the selected channel' do
        expect(joined_result).to contain_exactly(helm_package_file2)
      end

      context 'with package files pending destruction' do
        let_it_be(:package_file_pending_destruction) { create(:helm_package_file, :pending_destruction, package: helm_package, channel: 'alpha') }

        it 'does not return them' do
          expect(joined_result).to contain_exactly(helm_package_file2)
        end
      end
    end
  end

  describe '#pipelines' do
    let_it_be_with_refind(:package_file) { create(:package_file) }

    subject { package_file.pipelines }

    context 'package_file without pipeline' do
      it { is_expected.to be_empty }
    end

    context 'package_file with pipeline' do
      let_it_be(:pipeline) { create(:ci_pipeline) }
      let_it_be(:pipeline2) { create(:ci_pipeline) }

      before do
        package_file.package_file_build_infos.create!(pipeline: pipeline)
        package_file.package_file_build_infos.create!(pipeline: pipeline2)
      end

      it { is_expected.to contain_exactly(pipeline, pipeline2) }
    end
  end

  describe '#update_file_store callback' do
    let_it_be(:package_file) { build(:package_file, :nuget, size: nil) }

    subject(:save_result) { package_file.save! }

    it 'updates metadata columns' do
      expect(package_file)
        .to receive(:update_file_store)
        .and_call_original

      expect { save_result }.to change { package_file.size }.from(nil).to(3513)
    end
  end

  context 'update callbacks' do
    subject(:save_result) { package_file.save! }

    shared_examples 'executing the default callback' do
      it 'executes the default callback' do
        expect(package_file).to receive(:remove_previously_stored_file)
        expect(package_file).not_to receive(:move_in_object_storage)

        save_result
      end
    end

    context 'with object storage disabled' do
      let(:package_file) { create(:package_file, file_name: 'file_name.txt') }

      before do
        stub_package_file_object_storage(enabled: false)
      end

      it_behaves_like 'executing the default callback'

      context 'with new_file_path set' do
        before do
          package_file.new_file_path = 'test'
        end

        it_behaves_like 'executing the default callback'
      end
    end

    context 'with object storage enabled' do
      let(:package_file) do
        create(
          :package_file,
          file_name: 'file_name.txt',
          file: CarrierWaveStringFile.new_file(
            file_content: 'content',
            filename: 'file_name.txt',
            content_type: 'text/plain'
          ),
          file_store: ::Packages::PackageFileUploader::Store::REMOTE
        )
      end

      before do
        stub_package_file_object_storage(enabled: true)
      end

      it_behaves_like 'executing the default callback'

      context 'with new_file_path set' do
        before do
          package_file.new_file_path = 'test'
        end

        it 'executes the move_in_object_storage callback' do
          expect(package_file).not_to receive(:remove_previously_stored_file)
          expect(package_file).to receive(:move_in_object_storage).and_call_original
          expect(package_file.file.file).to receive(:copy_to).and_call_original
          expect(package_file.file.file).to receive(:delete).and_call_original

          save_result
        end
      end
    end
  end

  context 'status scopes' do
    let_it_be(:package) { create(:generic_package) }
    let_it_be(:default_package_file) { create(:package_file, package: package) }
    let_it_be(:pending_destruction_package_file) { create(:package_file, :pending_destruction, package: package) }

    describe '.installable' do
      subject { package.installable_package_files }

      it 'does not include non-displayable packages', :aggregate_failures do
        is_expected.to include(default_package_file)
        is_expected.not_to include(pending_destruction_package_file)
      end
    end

    describe '.with_status' do
      subject { described_class.with_status(:pending_destruction) }

      it { is_expected.to contain_exactly(pending_destruction_package_file) }
    end
  end

  describe '.installable_statuses' do
    it_behaves_like 'installable statuses'
  end

  describe '#file_name_for_download' do
    subject { package_file.file_name_for_download }

    context 'with a simple file name' do
      let(:package_file) { package_file1 }

      it { is_expected.to eq(package_file.file_name) }
    end

    context 'with a file name with encoded slashes' do
      let(:package_file) { package_file5 }

      it 'returns the last component of the file name' do
        is_expected.to eq('formatted')
      end
    end
  end

  it_behaves_like 'object storable' do
    let(:locally_stored) do
      package_file = create(:package_file)

      if package_file.file_store == ObjectStorage::Store::REMOTE
        package_file.update_column(described_class::STORE_COLUMN, ObjectStorage::Store::LOCAL)
      end

      package_file
    end

    let(:remotely_stored) do
      package_file = create(:package_file)

      if package_file.file_store == ObjectStorage::Store::LOCAL
        package_file.update_column(described_class::STORE_COLUMN, ObjectStorage::Store::REMOTE)
      end

      package_file
    end
  end
end
