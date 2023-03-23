# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Npm::PackagePresenter, feature_category: :package_registry do
  let_it_be(:metadata) do
    {
      name: 'foo',
      versions: { '1.0.0' => { 'dist' => { 'tarball' => 'http://localhost/tarball.tgz' } } },
      dist_tags: { 'latest' => '1.0.0' }
    }
  end

  subject { described_class.new(metadata) }

  describe '#name' do
    it 'returns the name' do
      expect(subject.name).to eq('foo')
    end
  end

  describe '#versions' do
    it 'returns the versions' do
      expect(subject.versions).to eq({ '1.0.0' => { 'dist' => { 'tarball' => 'http://localhost/tarball.tgz' } } })
    end
  end

  describe '#dist_tags' do
    it 'returns the dist_tags' do
      expect(subject.dist_tags).to eq({ 'latest' => '1.0.0' })
    end
  end
end
