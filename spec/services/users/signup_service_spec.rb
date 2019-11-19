# frozen_string_literal: true

require 'spec_helper'

describe Users::SignupService do
  let(:user) { create(:user, setup_for_company: true) }

  describe '#execute' do
    context 'when updating name' do
      it 'updates the name attribute' do
        result = update_user(user, name: 'New Name')

        expect(result).to eq(status: :success)
        expect(user.reload.name).to eq('New Name')
      end

      it 'returns an error result when name is missing' do
        result = update_user(user, name: '')

        expect(user.reload.name).not_to be_blank
        expect(result[:status]).to eq(:error)
        expect(result[:message]).to include("Name can't be blank")
      end
    end

    context 'when updating role' do
      it 'updates the role attribute' do
        result = update_user(user, role: 'development_team_lead')

        expect(result).to eq(status: :success)
        expect(user.reload.role).to eq('development_team_lead')
      end

      it 'returns an error result when role is missing' do
        result = update_user(user, role: '')

        expect(user.reload.role).not_to be_blank
        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq("Role can't be blank")
      end
    end

    context 'when updating setup_for_company' do
      it 'updates the setup_for_company attribute' do
        result = update_user(user, setup_for_company: 'false')

        expect(result).to eq(status: :success)
        expect(user.reload.setup_for_company).to be(false)
      end

      it 'returns an error result when setup_for_company is missing' do
        result = update_user(user, setup_for_company: '')

        expect(user.reload.setup_for_company).not_to be_blank
        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq("Setup for company can't be blank")
      end
    end

    def update_user(user, opts)
      described_class.new(user, opts).execute
    end
  end
end
