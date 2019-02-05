# frozen_string_literal: true

require 'spec_helper'

describe ApplicationRecord do
  describe '#id_in' do
    let(:records) { create_list(:user, 3) }

    it 'returns records of the ids' do
      expect(User.id_in(records.last(2).map(&:id))).to eq(records.last(2))
    end
  end

  describe '#safe_find_or_create_by' do
    it 'creates the user avoiding race conditions' do
      expect(Suggestion).to receive(:find_or_create_by).and_raise(ActiveRecord::RecordNotUnique)
      allow(Suggestion).to receive(:find_or_create_by).and_call_original

      expect { Suggestion.safe_find_or_create_by(build(:suggestion).attributes) }
        .to change { Suggestion.count }.by(1)
    end
  end
end
