# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/app_logger'
require_relative '../../../../../app/models/concerns/namespaces/stateful/state_precedence'

RSpec.describe Namespaces::Stateful::StatePrecedence, feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax

  before do
    stub_const(
      'Namespaces::Stateful::PROPAGATED_STATES',
      %i[ancestor_inherited archived deletion_scheduled maintenance]
    )
  end

  describe '.overwritable_states' do
    subject(:result) { described_class.overwritable_states(source_state, target_state) }

    context 'when propagating ancestor_inherited (reversal / restoration)' do
      context 'when unarchiving (archived -> ancestor_inherited)' do
        let(:source_state) { :archived }
        let(:target_state) { :ancestor_inherited }

        it 'overwrites only archived descendants, not deletion_scheduled' do
          expect(result).to eq([:archived])
        end
      end

      context 'when restoring (deletion_scheduled -> ancestor_inherited)' do
        let(:source_state) { :deletion_scheduled }
        let(:target_state) { :ancestor_inherited }

        it 'overwrites both deletion_scheduled and archived descendants' do
          expect(result).to contain_exactly(:deletion_scheduled, :archived)
        end
      end

      context 'when exiting maintenance (maintenance -> ancestor_inherited)' do
        let(:source_state) { :maintenance }
        let(:target_state) { :ancestor_inherited }

        it 'overwrites every non-default state up to maintenance' do
          expect(result).to contain_exactly(:archived, :deletion_scheduled, :maintenance)
        end
      end

      context 'when source_state is ancestor_inherited (no state to revert)' do
        let(:source_state) { :ancestor_inherited }
        let(:target_state) { :ancestor_inherited }

        it 'returns an empty array (nothing to revert)' do
          expect(result).to be_empty
        end
      end
    end

    context 'when propagating archived (precedence 1)' do
      context 'when archiving (ancestor_inherited -> archived)' do
        let(:source_state) { :ancestor_inherited }
        let(:target_state) { :archived }

        it 'overwrites only ancestor_inherited descendants' do
          expect(result).to eq([:ancestor_inherited])
        end
      end

      context 'when source_state is archived (equal precedence)' do
        let(:source_state) { :archived }
        let(:target_state) { :archived }

        it 'overwrites ancestor_inherited descendants' do
          expect(result).to eq([:ancestor_inherited])
        end
      end

      context 'when source_state is deletion_scheduled (higher precedence than target archived)' do
        let(:source_state) { :deletion_scheduled }
        let(:target_state) { :archived }

        it 'overwrites ancestor_inherited descendants' do
          expect(result).to eq([:ancestor_inherited])
        end
      end
    end

    context 'when propagating deletion_scheduled (precedence 2)' do
      context 'when scheduling deletion from ancestor_inherited (ancestor_inherited -> deletion_scheduled)' do
        let(:source_state) { :ancestor_inherited }
        let(:target_state) { :deletion_scheduled }

        it 'overwrites ancestor_inherited and archived descendants' do
          expect(result).to contain_exactly(:ancestor_inherited, :archived)
        end
      end

      context 'when scheduling deletion from archived (archived -> deletion_scheduled)' do
        let(:source_state) { :archived }
        let(:target_state) { :deletion_scheduled }

        it 'overwrites ancestor_inherited and archived descendants' do
          expect(result).to contain_exactly(:ancestor_inherited, :archived)
        end
      end

      context 'when source_state is deletion_scheduled (equal precedence)' do
        let(:source_state) { :deletion_scheduled }
        let(:target_state) { :deletion_scheduled }

        it 'overwrites ancestor_inherited and archived descendants' do
          expect(result).to contain_exactly(:ancestor_inherited, :archived)
        end
      end
    end

    context 'when propagating maintenance (highest precedence)' do
      context 'when entering maintenance from ancestor_inherited (ancestor_inherited -> maintenance)' do
        let(:source_state) { :ancestor_inherited }
        let(:target_state) { :maintenance }

        it 'overwrites ancestor_inherited, archived, and deletion_scheduled descendants' do
          expect(result).to contain_exactly(:ancestor_inherited, :archived, :deletion_scheduled)
        end
      end

      context 'when entering maintenance from archived (archived -> maintenance)' do
        let(:source_state) { :archived }
        let(:target_state) { :maintenance }

        it 'overwrites ancestor_inherited, archived, and deletion_scheduled descendants' do
          expect(result).to contain_exactly(:ancestor_inherited, :archived, :deletion_scheduled)
        end
      end

      context 'when entering maintenance from deletion_scheduled (deletion_scheduled -> maintenance)' do
        let(:source_state) { :deletion_scheduled }
        let(:target_state) { :maintenance }

        it 'overwrites ancestor_inherited, archived, and deletion_scheduled descendants' do
          expect(result).to contain_exactly(:ancestor_inherited, :archived, :deletion_scheduled)
        end
      end

      context 'when entering maintenance from a non-propagated source (transfer_scheduled -> maintenance)' do
        let(:source_state) { :transfer_scheduled }
        let(:target_state) { :maintenance }

        it 'overwrites ancestor_inherited, archived, and deletion_scheduled descendants' do
          expect(result).to contain_exactly(:ancestor_inherited, :archived, :deletion_scheduled)
        end
      end

      context 'when source_state is maintenance (equal precedence)' do
        let(:source_state) { :maintenance }
        let(:target_state) { :maintenance }

        it 'overwrites every non-default state up to maintenance (exit-maintenance semantics)' do
          expect(result).to contain_exactly(:archived, :deletion_scheduled, :maintenance)
        end
      end
    end

    context 'when exiting maintenance to a lower or non-propagated state' do
      where(:target_state) do
        [:archived, :deletion_scheduled, :transfer_scheduled]
      end

      with_them do
        let(:source_state) { :maintenance }

        it 'overwrites every non-default state up to maintenance regardless of the target state' do
          expect(result).to contain_exactly(:archived, :deletion_scheduled, :maintenance)
        end
      end
    end

    context 'when entering a propagated state from a non-propagated source' do
      # Forward propagation depends solely on the target's precedence, so a
      # non-propagated source (e.g. transfer_scheduled, transfer_in_progress)
      # still overwrites descendants according to the target.
      where(:source_state, :target_state, :expected) do
        :transfer_scheduled   | :maintenance        | [:ancestor_inherited, :archived, :deletion_scheduled]
        :transfer_scheduled   | :archived           | [:ancestor_inherited]
        :transfer_scheduled   | :deletion_scheduled | [:ancestor_inherited, :archived]
        :transfer_in_progress | :maintenance        | [:ancestor_inherited, :archived, :deletion_scheduled]
        :creation_in_progress | :archived           | [:ancestor_inherited]
        :creation_in_progress | :deletion_scheduled | [:ancestor_inherited, :archived]
        :creation_in_progress | :maintenance        | [:ancestor_inherited, :archived, :deletion_scheduled]
      end

      with_them do
        it 'overwrites descendants according to the target precedence, ignoring the source' do
          expect(result).to match_array(expected)
        end

        it 'does not log a non-propagatable state error' do
          expect(Gitlab::AppLogger).not_to receive(:error)

          result
        end
      end
    end

    context 'when the target is outside the propagation-relevant set' do
      where(:source_state, :target_state) do
        :creation_in_progress  | :ancestor_inherited
        :deletion_in_progress  | :ancestor_inherited
        :transfer_in_progress  | :ancestor_inherited
        :transfer_scheduled    | :ancestor_inherited
        :ancestor_inherited    | :creation_in_progress
        :ancestor_inherited    | :deletion_in_progress
        :ancestor_inherited    | :transfer_in_progress
        :ancestor_inherited    | :transfer_scheduled
        :creation_in_progress  | :creation_in_progress
      end

      with_them do
        it 'returns an empty array' do
          allow(Gitlab::AppLogger).to receive(:error)

          expect(result).to be_empty
        end

        it 'logs an error for the non-propagatable state' do
          allow(Gitlab::AppLogger).to receive(:error)

          result

          expect(Gitlab::AppLogger).to have_received(:error).with(
            hash_including(message: 'Non-propagatable state encountered in state precedence lookup')
          )
        end
      end
    end

    context 'with all propagation-relevant source/target combinations' do
      where(:source_state, :target_state, :expected) do
        :ancestor_inherited | :ancestor_inherited | []
        :ancestor_inherited | :archived           | [:ancestor_inherited]
        :ancestor_inherited | :deletion_scheduled | [:ancestor_inherited, :archived]
        :ancestor_inherited | :maintenance        | [:ancestor_inherited, :archived, :deletion_scheduled]
        :archived           | :ancestor_inherited | [:archived]
        :archived           | :archived           | [:ancestor_inherited]
        :archived           | :deletion_scheduled | [:ancestor_inherited, :archived]
        :archived           | :maintenance        | [:ancestor_inherited, :archived, :deletion_scheduled]
        :deletion_scheduled | :ancestor_inherited | [:deletion_scheduled, :archived]
        :deletion_scheduled | :archived           | [:ancestor_inherited]
        :deletion_scheduled | :deletion_scheduled | [:ancestor_inherited, :archived]
        :deletion_scheduled | :maintenance        | [:ancestor_inherited, :archived, :deletion_scheduled]
        :maintenance        | :ancestor_inherited | [:archived, :deletion_scheduled, :maintenance]
        :maintenance        | :archived           | [:archived, :deletion_scheduled, :maintenance]
        :maintenance        | :deletion_scheduled | [:archived, :deletion_scheduled, :maintenance]
        :maintenance        | :maintenance        | [:archived, :deletion_scheduled, :maintenance]
      end

      with_them do
        it 'returns the expected overwritable states' do
          expect(result).to match_array(expected)
        end
      end
    end
  end
end
