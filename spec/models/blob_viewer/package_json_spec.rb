# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BlobViewer::PackageJson, feature_category: :source_code_management do
  include FakeBlobHelpers

  let(:project) { build_stubbed(:project) }
  let(:data) do
    <<-SPEC.strip_heredoc
      {
        "name": "module-name",
        "version": "10.3.1"
      }
    SPEC
  end

  let(:blob) { fake_blob(path: 'package.json', data: data) }

  subject { described_class.new(blob) }

  describe '#package_name' do
    it 'returns the package name' do
      expect(subject).to receive(:prepare!)

      expect(subject.package_name).to eq('module-name')
    end
  end

  context 'yarn' do
    let(:data) do
      <<-SPEC.strip_heredoc
        {
          "name": "module-name",
          "version": "10.3.1",
          "engines": {
            "yarn": "^2.4.0"
          }
        }
      SPEC
    end

    let(:blob) { fake_blob(path: 'package.json', data: data) }

    subject { described_class.new(blob) }

    describe '#package_url' do
      it 'returns the package URL', :aggregate_failures do
        expect(subject).to receive(:prepare!)

        expect(subject.package_url).to eq("https://yarnpkg.com/package/#{subject.package_name}")
      end
    end

    describe '#manager_url' do
      it 'returns the manager URL', :aggregate_failures do
        expect(subject).to receive(:prepare!)

        expect(subject.manager_url).to eq("https://yarnpkg.com/")
      end
    end

    context 'when json is an array' do
      let(:data) { '[]' }

      it 'does not raise an error', :aggregate_failures do
        expect(subject).to receive(:prepare!)

        expect { subject.yarn? }.not_to raise_error
        expect(subject.yarn?).to be_falsey
      end
    end
  end

  context 'npm' do
    describe '#package_url' do
      it 'returns the package URL', :aggregate_failures do
        expect(subject).to receive(:prepare!)

        expect(subject.package_url).to eq("https://www.npmjs.com/package/#{subject.package_name}")
      end
    end

    describe '#manager_url' do
      it 'returns the manager URL', :aggregate_failures do
        expect(subject).to receive(:prepare!)

        expect(subject.manager_url).to eq("https://www.npmjs.com/")
      end
    end
  end

  describe '#package_type' do
    it 'returns "package"' do
      expect(subject).to receive(:prepare!)

      expect(subject.package_type).to eq('package')
    end
  end

  context 'when package.json has "private": true' do
    let(:homepage) { 'http://example.com' }
    let(:data) do
      <<-SPEC.strip_heredoc
      {
        "name": "module-name",
        "version": "10.3.1",
        "private": true,
        "homepage": #{homepage.to_json}
      }
      SPEC
    end

    let(:blob) { fake_blob(path: 'package.json', data: data) }

    subject { described_class.new(blob) }

    describe '#package_url' do
      context 'when the homepage has a valid URL' do
        it 'returns homepage URL' do
          expect(subject).to receive(:prepare!)

          expect(subject.package_url).to eq(homepage)
        end
      end

      context 'when the homepage has an invalid URL' do
        let(:homepage) { 'javascript:alert()' }

        it 'returns nil' do
          expect(subject).to receive(:prepare!)

          expect(subject.package_url).to be_nil
        end
      end
    end

    describe '#package_type' do
      it 'returns "private package"' do
        expect(subject).to receive(:prepare!)

        expect(subject.package_type).to eq('private package')
      end
    end
  end
end
