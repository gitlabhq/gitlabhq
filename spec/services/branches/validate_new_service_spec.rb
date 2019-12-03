# frozen_string_literal: true

require 'spec_helper'

describe Branches::ValidateNewService do
  let(:project) { create(:project, :repository) }
  subject(:service) { described_class.new(project) }

  describe '#execute' do
    context 'validation' do
      it 'returns error with an invalid branch name' do
        result = service.execute('refs/heads/invalid_branch')

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq('Branch name is invalid')
      end

      it 'returns success with a valid branch name' do
        result = service.execute('valid_branch_name')

        expect(result[:status]).to eq(:success)
      end
    end

    context 'branch exist' do
      it 'returns error when branch exists' do
        result = service.execute('master')

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq('Branch already exists')
      end

      it 'returns success when branch name is available' do
        result = service.execute('valid_branch_name')

        expect(result[:status]).to eq(:success)
      end
    end
  end
end
