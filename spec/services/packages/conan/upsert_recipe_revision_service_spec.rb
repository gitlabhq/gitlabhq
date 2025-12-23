# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Conan::UpsertRecipeRevisionService, feature_category: :package_registry do
  let_it_be(:package) { create(:conan_package, without_package_files: true) }
  let_it_be(:recipe_revision_value) { OpenSSL::Digest.hexdigest('MD5', 'valid_recipe_revision') }

  let(:status) { :processing }

  describe '#execute!', :aggregate_failures do
    subject(:response) { described_class.new(package, recipe_revision_value, status).execute! }

    shared_examples 'returns existing recipe revision' do
      it 'returns existing recipe revision' do
        expect { response }.not_to change { Packages::Conan::RecipeRevision.count }

        expect(response).to be_success
        expect(response[:recipe_revision_id]).to eq(recipe_revision.id)
        expect(recipe_revision.reload.status).to eq(status.to_s)
      end
    end

    context 'when the recipe revision doesn\'t exist' do
      it 'creates the recipe revision' do
        expect { response }.to change { Packages::Conan::RecipeRevision.count }.by(1)

        recipe_revision = Packages::Conan::RecipeRevision.last
        expect(recipe_revision).to have_attributes(revision: recipe_revision_value, status: status.to_s)
        expect(response).to be_success
        expect(response[:recipe_revision_id]).to eq(recipe_revision.id)
      end

      context 'when the recipe revision is invalid' do
        let(:recipe_revision_value) { nil }

        it 'raises the error' do
          expect { response }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context 'when the recipe revision already exists' do
      let_it_be(:recipe_revision) do
        create(:conan_recipe_revision, :processing, package: package, revision: recipe_revision_value)
      end

      it_behaves_like 'returns existing recipe revision'

      context 'when existing revision is in status `default`' do
        before do
          recipe_revision.default!
        end

        it_behaves_like 'returns existing recipe revision'
      end
    end
  end
end
