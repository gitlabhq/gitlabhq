require 'spec_helper'

describe DeleteBranchService, services: true do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:service) { described_class.new(project, user) }

  describe '#execute' do
    let(:result) { service.execute('feature') }

    context 'when user has access to push to repository' do
      before do
        project.team << [user, :developer]
      end

      it 'removes the branch' do
        expect(result[:status]).to eq :success
      end
    end

    context 'when user does not have access to push to repository' do
      it 'does not remove branch' do
        expect(result[:status]).to eq :error
        expect(result[:message]).to eq 'You dont have push access to repo'
      end
    end
  end
end
