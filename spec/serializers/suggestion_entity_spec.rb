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
        allow(suggestion).to receive(:appliable?).and_return(appliable)
      end

      context 'and suggestion is appliable' do
        let(:appliable) { true }

        it 'returns nil' do
          expect(inapplicable_reason).to be_nil
        end
      end

      context 'but suggestion is not applicable' do
        let(:appliable) { false }

        before do
          allow(suggestion).to receive(:inapplicable_reason).and_return(reason)
        end

        context 'and merge request was merged' do
          let(:reason) { :merge_request_merged }

          it 'returns appropriate message' do
            expect(inapplicable_reason).to eq("This merge request was merged. To apply this suggestion, edit this file directly.")
          end
        end

        context 'and source branch was deleted' do
          let(:reason) { :source_branch_deleted }

          it 'returns appropriate message' do
            expect(inapplicable_reason).to eq("Can't apply as the source branch was deleted.")
          end
        end

        context 'and merge request is closed' do
          let(:reason) { :merge_request_closed }

          it 'returns appropriate message' do
            expect(inapplicable_reason).to eq("This merge request is closed. To apply this suggestion, edit this file directly.")
          end
        end

        context 'and suggestion is outdated' do
          let(:reason) { :outdated }

          before do
            allow(suggestion).to receive(:single_line?).and_return(single_line)
          end

          context 'and suggestion is for a single line' do
            let(:single_line) { true }

            it 'returns appropriate message' do
              expect(inapplicable_reason).to eq("Can't apply as this line was changed in a more recent version.")
            end
          end

          context 'and suggestion is for multiple lines' do
            let(:single_line) { false }

            it 'returns appropriate message' do
              expect(inapplicable_reason).to eq("Can't apply as these lines were changed in a more recent version.")
            end
          end
        end

        context 'and suggestion has the same content' do
          let(:reason) { :same_content }

          it 'returns appropriate message' do
            expect(inapplicable_reason).to eq("This suggestion already matches its content.")
          end
        end

        context 'and suggestion is inapplicable for other reasons' do
          let(:reason) { :some_other_reason }

          it 'returns default message' do
            expect(inapplicable_reason).to eq("Can't apply this suggestion.")
          end
        end
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
