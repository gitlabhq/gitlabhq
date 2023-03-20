# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Npm::CreateTagService, feature_category: :package_registry do
  let(:package) { create(:npm_package) }
  let(:tag_name) { 'test-tag' }

  describe '#execute' do
    subject { described_class.new(package, tag_name).execute }

    shared_examples 'it creates the tag' do
      it { expect { subject }.to change { Packages::Tag.count }.by(1) }
      it { expect(subject.name).to eq(tag_name) }

      it 'adds tag to the package' do
        tag = subject
        expect(package.reload.tags).to match_array([tag])
      end
    end

    context 'with no existing tag name' do
      it_behaves_like 'it creates the tag'
    end

    context 'with exisiting tag name' do
      let!(:package_tag2) { create(:packages_tag, package: package2, name: tag_name) }

      context 'on package with different name' do
        let!(:package2) { create(:npm_package, project: package.project) }

        it_behaves_like 'it creates the tag'
      end

      context 'on different package type' do
        let!(:package2) { create(:conan_package, project: package.project, name: 'conan_package_name', version: package.version) }

        it_behaves_like 'it creates the tag'
      end

      context 'on same package with different version' do
        let!(:package2) { create(:npm_package, project: package.project, name: package.name, version: '5.0.0-testing') }

        it { expect { subject }.to not_change { Packages::Tag.count } }
        it { expect(subject.name).to eq(tag_name) }

        it 'adds tag to the package' do
          tag = subject
          expect(package.reload.tags).to match_array([tag])
          expect(package2.reload.tags).to be_empty
        end
      end
    end
  end
end
