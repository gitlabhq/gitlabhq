# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Conan::SearchService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  let!(:conan_package) { create(:conan_package, project: project) }
  let!(:conan_package2) { create(:conan_package, project: project) }

  subject { described_class.new(user, query: query) }

  before do
    project.add_developer(user)
  end

  describe '#execute' do
    context 'with wildcard' do
      let(:partial_name) { conan_package.name.first[0, 3] }
      let(:query) { "#{partial_name}*" }

      it 'makes a wildcard query' do
        result = subject.execute

        expect(result.status).to eq :success
        expect(result.payload).to eq(results: [conan_package.conan_recipe, conan_package2.conan_recipe])
      end
    end

    context 'with only wildcard' do
      let(:query) { '*' }

      it 'returns empty' do
        result = subject.execute

        expect(result.status).to eq :success
        expect(result.payload).to eq(results: [])
      end
    end

    context 'with no wildcard' do
      let(:query) { conan_package.name }

      it 'makes a search using the beginning of the recipe' do
        result = subject.execute

        expect(result.status).to eq :success
        expect(result.payload).to eq(results: [conan_package.conan_recipe])
      end
    end

    context 'with full recipe match' do
      let(:query) { conan_package.conan_recipe }

      it 'makes an exact search' do
        result = subject.execute

        expect(result.status).to eq :success
        expect(result.payload).to eq(results: [conan_package.conan_recipe])
      end
    end

    context 'with malicious query' do
      let(:query) { 'DROP TABLE foo;' }

      it 'returns empty' do
        result = subject.execute

        expect(result.status).to eq :success
        expect(result.payload).to eq(results: [])
      end
    end
  end
end
