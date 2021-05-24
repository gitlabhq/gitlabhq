# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'Debian Component File' do |container_type, can_freeze|
  let_it_be(:container1, freeze: can_freeze) { create(container_type) } # rubocop:disable Rails/SaveBang
  let_it_be(:container2, freeze: can_freeze) { create(container_type) } # rubocop:disable Rails/SaveBang
  let_it_be(:distribution1, freeze: can_freeze) { create("debian_#{container_type}_distribution", container: container1) }
  let_it_be(:distribution2, freeze: can_freeze) { create("debian_#{container_type}_distribution", container: container2) }
  let_it_be(:architecture1_1, freeze: can_freeze) { create("debian_#{container_type}_architecture", distribution: distribution1) }
  let_it_be(:architecture1_2, freeze: can_freeze) { create("debian_#{container_type}_architecture", distribution: distribution1) }
  let_it_be(:architecture2_1, freeze: can_freeze) { create("debian_#{container_type}_architecture", distribution: distribution2) }
  let_it_be(:architecture2_2, freeze: can_freeze) { create("debian_#{container_type}_architecture", distribution: distribution2) }
  let_it_be(:component1_1, freeze: can_freeze) { create("debian_#{container_type}_component", distribution: distribution1) }
  let_it_be(:component1_2, freeze: can_freeze) { create("debian_#{container_type}_component", distribution: distribution1) }
  let_it_be(:component2_1, freeze: can_freeze) { create("debian_#{container_type}_component", distribution: distribution2) }
  let_it_be(:component2_2, freeze: can_freeze) { create("debian_#{container_type}_component", distribution: distribution2) }

  let_it_be_with_refind(:component_file_with_architecture) { create("debian_#{container_type}_component_file", component: component1_1, architecture: architecture1_1) }
  let_it_be(:component_file_other_architecture, freeze: can_freeze) { create("debian_#{container_type}_component_file", component: component1_1, architecture: architecture1_2) }
  let_it_be(:component_file_other_component, freeze: can_freeze) { create("debian_#{container_type}_component_file", component: component1_2, architecture: architecture1_1) }
  let_it_be(:component_file_other_compression_type, freeze: can_freeze) { create("debian_#{container_type}_component_file", component: component1_1, architecture: architecture1_1, compression_type: :xz) }
  let_it_be(:component_file_other_file_md5, freeze: can_freeze) { create("debian_#{container_type}_component_file", component: component1_1, architecture: architecture1_1, file_md5: 'other_md5') }
  let_it_be(:component_file_other_file_sha256, freeze: can_freeze) { create("debian_#{container_type}_component_file", component: component1_1, architecture: architecture1_1, file_sha256: 'other_sha256') }
  let_it_be(:component_file_other_container, freeze: can_freeze) { create("debian_#{container_type}_component_file", component: component2_1, architecture: architecture2_1) }
  let_it_be_with_refind(:component_file_with_file_type_source) { create("debian_#{container_type}_component_file", :source, component: component1_1) }
  let_it_be(:component_file_with_file_type_di_packages, freeze: can_freeze) { create("debian_#{container_type}_component_file", :di_packages, component: component1_1, architecture: architecture1_1) }

  subject { component_file_with_architecture }

  describe 'relationships' do
    context 'with stubbed uploader' do
      before do
        allow_next_instance_of(Packages::Debian::ComponentFileUploader) do |uploader|
          allow(uploader).to receive(:dynamic_segment).and_return('stubbed')
        end
      end

      it { is_expected.to belong_to(:component).class_name("Packages::Debian::#{container_type.capitalize}Component").inverse_of(:files) }
    end

    context 'with packages file_type' do
      it { is_expected.to belong_to(:architecture).class_name("Packages::Debian::#{container_type.capitalize}Architecture").inverse_of(:files) }
    end

    context 'with :source file_type' do
      subject { component_file_with_file_type_source }

      it { is_expected.to belong_to(:architecture).class_name("Packages::Debian::#{container_type.capitalize}Architecture").inverse_of(:files).optional }
    end
  end

  describe 'validations' do
    describe "#component" do
      before do
        allow_next_instance_of(Packages::Debian::ComponentFileUploader) do |uploader|
          allow(uploader).to receive(:dynamic_segment).and_return('stubbed')
        end
      end

      it { is_expected.to validate_presence_of(:component) }
    end

    describe "#architecture" do
      context 'with packages file_type' do
        it { is_expected.to validate_presence_of(:architecture) }
      end

      context 'with :source file_type' do
        subject { component_file_with_file_type_source }

        it { is_expected.to validate_absence_of(:architecture) }
      end
    end

    describe '#file_type' do
      it { is_expected.to validate_presence_of(:file_type) }

      it { is_expected.to allow_value(:packages).for(:file_type) }
    end

    describe '#compression_type' do
      it { is_expected.not_to validate_presence_of(:compression_type) }

      it { is_expected.to allow_value(nil).for(:compression_type) }
      it { is_expected.to allow_value(:gz).for(:compression_type) }
    end

    describe '#file' do
      subject { component_file_with_architecture.file }

      context 'the uploader api' do
        it { is_expected.to respond_to(:store_dir) }
        it { is_expected.to respond_to(:cache_dir) }
        it { is_expected.to respond_to(:work_dir) }
      end
    end

    describe '#file_store' do
      it { is_expected.to validate_presence_of(:file_store) }
    end

    describe '#file_md5' do
      it { is_expected.to validate_presence_of(:file_md5) }
    end

    describe '#file_sha256' do
      it { is_expected.to validate_presence_of(:file_sha256) }
    end
  end

  describe 'scopes' do
    describe '.with_container' do
      subject { described_class.with_container(container2) }

      it do
        expect(subject.to_a).to contain_exactly(component_file_other_container)
      end
    end

    describe '.with_codename_or_suite' do
      subject { described_class.with_codename_or_suite(distribution2.codename) }

      it do
        expect(subject.to_a).to contain_exactly(component_file_other_container)
      end
    end

    describe '.with_component_name' do
      subject { described_class.with_component_name(component1_2.name) }

      it do
        expect(subject.to_a).to contain_exactly(component_file_other_component)
      end
    end

    describe '.with_file_type' do
      subject { described_class.with_file_type(:source) }

      it do
        expect(subject.to_a).to contain_exactly(component_file_with_file_type_source)
      end
    end

    describe '.with_architecture' do
      subject { described_class.with_architecture(architecture1_2) }

      it do
        expect(subject.to_a).to contain_exactly(component_file_other_architecture)
      end
    end

    describe '.with_architecture_name' do
      subject { described_class.with_architecture_name(architecture1_2.name) }

      it do
        expect(subject.to_a).to contain_exactly(component_file_other_architecture)
      end
    end

    describe '.with_compression_type' do
      subject { described_class.with_compression_type(:xz) }

      it do
        expect(subject.to_a).to contain_exactly(component_file_other_compression_type)
      end
    end

    describe '.with_file_sha256' do
      subject { described_class.with_file_sha256('other_sha256') }

      it do
        expect(subject.to_a).to contain_exactly(component_file_other_file_sha256)
      end
    end

    describe '.updated_before' do
      let_it_be(:component_file1) { create("debian_#{container_type}_component_file", component: component1_1, architecture: architecture1_1, updated_at: 4.hours.ago) }
      let_it_be(:component_file2) { create("debian_#{container_type}_component_file", component: component1_1, architecture: architecture1_1, updated_at: 3.hours.ago) }
      let_it_be(:component_file3) { create("debian_#{container_type}_component_file", component: component1_1, architecture: architecture1_1, updated_at: 1.hour.ago) }

      subject { described_class.updated_before(2.hours.ago) }

      it do
        expect(subject.to_a).to contain_exactly(component_file1, component_file2)
      end
    end
  end

  describe 'callbacks' do
    let(:component_file) { build("debian_#{container_type}_component_file", component: component1_1, architecture: architecture1_1, size: nil) }

    subject { component_file.save! }

    it 'updates metadata columns' do
      expect(component_file)
        .to receive(:update_file_store)
        .and_call_original

      expect(component_file)
        .to receive(:update_column)
        .with(:file_store, ::Packages::PackageFileUploader::Store::LOCAL)
        .and_call_original

      expect { subject }.to change { component_file.size }.from(nil).to(74)
    end
  end

  describe '#relative_path' do
    context 'with a Packages file_type' do
      subject { component_file_with_architecture.relative_path }

      it { is_expected.to eq("#{component1_1.name}/binary-#{architecture1_1.name}/Packages") }
    end

    context 'with a Source file_type' do
      subject { component_file_with_file_type_source.relative_path }

      it { is_expected.to eq("#{component1_1.name}/source/Source") }
    end

    context 'with a DI Packages file_type' do
      subject { component_file_with_file_type_di_packages.relative_path }

      it { is_expected.to eq("#{component1_1.name}/debian-installer/binary-#{architecture1_1.name}/Packages") }
    end

    context 'with an xz compression_type' do
      subject { component_file_other_compression_type.relative_path }

      it { is_expected.to eq("#{component1_1.name}/binary-#{architecture1_1.name}/Packages.xz") }
    end
  end
end
