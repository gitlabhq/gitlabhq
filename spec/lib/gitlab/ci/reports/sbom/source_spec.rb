# frozen_string_literal: true

require 'fast_spec_helper'
require './app/models/concerns/enums/sbom'

RSpec.describe Gitlab::Ci::Reports::Sbom::Source, feature_category: :dependency_management do
  let(:attributes) do
    {
      type: type,
      data: { 'category' => 'development',
              'package_manager' => { 'name' => 'npm' },
              'language' => { 'name' => 'JavaScript' } }.merge(extra_attributes)
    }
  end

  subject(:source) { described_class.new(**attributes) }

  shared_examples_for 'it has correct attributes' do
    it 'has correct type and data' do
      expect(subject).to have_attributes(
        source_type: type,
        data: attributes[:data]
      )
    end
  end

  context 'when dependency scanning' do
    let(:type) { :dependency_scanning }
    let(:extra_attributes) do
      {
        'input_file' => { 'path' => 'package-lock.json' },
        'source_file' => { 'path' => 'package.json' }
      }
    end

    it_behaves_like 'it has correct attributes'

    describe '#source_file_path' do
      it 'returns the correct source_file_path' do
        expect(subject.source_file_path).to eq('package.json')
      end
    end

    describe '#input_file_path' do
      it 'returns the correct input_file_path' do
        expect(subject.input_file_path).to eq("package-lock.json")
      end
    end

    describe '#packager' do
      it 'returns the correct package manager name' do
        expect(subject.packager).to eq("npm")
      end
    end

    describe '#language' do
      it 'returns the correct language' do
        expect(subject.language).to eq("JavaScript")
      end
    end
  end

  context 'when container scanning' do
    let(:type) { :container_scanning }
    let(:extra_attributes) do
      {
        "image" => { "name" => "rhel", "tag" => "7.1" },
        "operating_system" => { "name" => "Red Hat Enterprise Linux", "version" => "7" }
      }
    end

    it_behaves_like 'it has correct attributes'

    describe "#image_name" do
      subject { source.image_name }

      it { is_expected.to eq("rhel") }
    end

    describe "#image_tag" do
      subject { source.image_tag }

      it { is_expected.to eq("7.1") }
    end

    describe "#operating_system_name" do
      subject { source.operating_system_name }

      it { is_expected.to eq("Red Hat Enterprise Linux") }
    end

    describe "#operating_system_version" do
      subject { source.operating_system_version }

      it { is_expected.to eq("7") }
    end
  end

  context 'when trivy' do
    let(:type) { :trivy }
    let(:attributes) do
      {
        type: type, data: {
          'FilePath' => '/usr/local/lib/node_modules/npm/node_modules/@colors/colors/package.json',
          'PkgType' => 'node-pkg'
        }
      }
    end

    describe '#packager' do
      subject { source.packager }

      it { is_expected.to eq('npm') }
    end

    describe '#input_file_path' do
      subject { source.input_file_path }

      it { is_expected.to eq('/usr/local/lib/node_modules/npm/node_modules/@colors/colors/package.json') }
    end
  end
end
