# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Conan::SinglePackageSearchService, feature_category: :package_registry do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  let!(:conan_package) { create(:conan_package, project: project) }
  let!(:conan_package2) { create(:conan_package, project: project) }

  describe '#execute' do
    context 'with a valid query and user with permissions' do
      before do
        allow_next_instance_of(described_class) do |service|
          allow(service).to receive(:can_access_project_package?).and_return(true)
        end
      end

      it 'returns the correct package' do
        [conan_package, conan_package2].each do |package|
          result = described_class.new(package.conan_recipe, user).execute

          expect(result.status).to eq :success
          expect(result[:results]).to match_array([package.conan_recipe])
        end
      end
    end

    context 'with a user without permissions' do
      before do
        allow_next_instance_of(described_class) do |service|
          allow(service).to receive(:can_access_project_package?).and_return(false)
        end
      end

      it 'returns an empty array' do
        result = described_class.new(conan_package.conan_recipe, user).execute

        expect(result.status).to eq :success
        expect(result[:results]).to match_array([])
      end
    end
  end
end
