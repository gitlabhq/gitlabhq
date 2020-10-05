# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ManifestImport::Manifest do
  let(:file) { File.open(Rails.root.join('spec/fixtures/aosp_manifest.xml')) }
  let(:manifest) { described_class.new(file) }

  describe '#valid?' do
    context 'valid file' do
      it { expect(manifest.valid?).to be true }
    end

    context 'missing or invalid attributes' do
      let(:file) { File.open(Rails.root.join('spec/fixtures/invalid_manifest.xml')) }

      it { expect(manifest.valid?).to be false }

      describe 'errors' do
        before do
          manifest.valid?
        end

        it { expect(manifest.errors).to include('Make sure a <remote> tag is present and is valid.') }
        it { expect(manifest.errors).to include('Make sure every <project> tag has name and path attributes.') }
      end
    end
  end

  describe '#projects' do
    it { expect(manifest.projects.size).to eq(660) }
    it { expect(manifest.projects[0][:name]).to eq('platform/build') }
    it { expect(manifest.projects[0][:path]).to eq('build/make') }
    it { expect(manifest.projects[0][:url]).to eq('https://android-review.googlesource.com/platform/build') }
  end
end
