# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Composer::ComposerJsonService, feature_category: :package_registry do
  describe '#execute' do
    let(:branch) { project.repository.find_branch('master') }
    let(:target) { branch.target }

    subject { described_class.new(project, target).execute }

    context 'with an existing file' do
      let(:project) { create(:project, :custom_repo, files: { 'composer.json' => json }) }

      context 'with a valid file' do
        let(:json) { '{ "name": "package-name"}' }

        it 'returns the parsed json' do
          expect(subject).to eq({ 'name' => 'package-name' })
        end
      end

      context 'with an invalid file' do
        let(:json) { '{ name": "package-name"}' }

        it 'raises an error' do
          expect { subject }.to raise_error(described_class::InvalidJson, /Invalid/)
        end
      end
    end

    context 'without the composer.json file' do
      let(:project) { create(:project, :repository) }

      it 'raises an error' do
        expect { subject }.to raise_error(described_class::InvalidJson, /not found/)
      end
    end
  end
end
