# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Commits::CreateService, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, refind: true) { create(:project, :repository) }
  let(:params) { {} }

  before do
    project.add_maintainer(user)
  end

  subject(:service) do
    described_class.new(project, user, start_branch: 'master', branch_name: 'master', **params)
  end

  describe '#execute' do
    describe 'when branch exists' do
      let(:params) { { branch_name: 'feature' } }

      it 'returns branch already exists error' do
        result = service.execute

        expect(result[:message]).to eq(
          "A branch called 'feature' already exists. Switch to that branch in order to make changes"
        )
      end

      describe 'for revert' do
        let(:params) { { branch_name: 'feature', revert: true } }

        it 'returns branch already exists error' do
          result = service.execute

          expect(result[:message]).to eq(
            "A branch called 'feature' already exists. Create merge request with that branch?"
          )
        end
      end
    end
  end
end
