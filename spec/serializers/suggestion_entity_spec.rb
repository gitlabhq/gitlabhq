# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SuggestionEntity do
  include RepoHelpers

  let(:user) { create(:user) }
  let(:request) { double('request', current_user: user) }
  let(:suggestion) { create(:suggestion) }
  let(:entity) { described_class.new(suggestion, request: request) }

  subject { entity.as_json }

  it 'exposes correct attributes' do
    expect(subject.keys).to match_array([:id, :appliable, :applied, :diff_lines, :current_user, :inapplicable_reason])
  end

  it 'exposes current user abilities' do
    expect(subject[:current_user]).to include(:can_apply)
  end

  describe 'inapplicable_reason' do
    let(:inapplicable_reason) { subject[:inapplicable_reason] }

    before do
      allow(Ability).to receive(:allowed?).and_call_original

      allow(Ability)
        .to receive(:allowed?)
        .with(user, :apply_suggestion, suggestion)
        .and_return(can_apply_suggestion)
    end

    context 'when user can apply suggestion' do
      let(:can_apply_suggestion) { true }

      before do
        allow(suggestion).to receive(:inapplicable_reason).and_return("Can't apply this suggestion.")
      end

      it 'returns the inapplicable reason' do
        expect(inapplicable_reason).to eq(suggestion.inapplicable_reason)
      end
    end

    context 'when user cannot apply suggestion' do
      let(:can_apply_suggestion) { false }

      it 'returns appropriate message' do
        expect(inapplicable_reason).to eq("You don't have write access to the source branch.")
      end
    end
  end
end
