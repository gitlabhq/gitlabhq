# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Labels::DestroyService, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  describe '#execute' do
    context 'when current_user is provided' do
      it 'destroys the label successfully' do
        label = create(:label, project: project)

        expect { described_class.new(user, label).execute }.to change { Label.count }.by(-1)
      end
    end

    it 'destroys the label' do
      label = create(:label, project: project)

      expect { described_class.new(user, label).execute }.to change { Label.count }.by(-1)
    end

    it 'returns the destroyed label' do
      label = create(:label, project: project)
      result = described_class.new(user, label).execute

      expect(result).to eq(label)
      expect(result).to be_destroyed
    end

    context 'when destroy fails' do
      it 'returns the label without destroying it' do
        label = create(:label, project: project)
        allow(label).to receive(:destroy).and_return(false)

        result = described_class.new(user, label).execute

        expect(result).to eq(label)
        expect(result).not_to be_destroyed
      end
    end
  end
end
