# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::Incidents::UpdateSeverityService do
  let_it_be(:user) { create(:user) }

  describe '#execute' do
    let(:severity) { 'low' }
    let(:system_note_worker) { ::IncidentManagement::AddSeveritySystemNoteWorker }

    subject(:update_severity) { described_class.new(issuable, user, severity).execute }

    before do
      allow(system_note_worker).to receive(:perform_async)
    end

    shared_examples 'adds a system note' do
      it 'calls AddSeveritySystemNoteWorker' do
        update_severity

        expect(system_note_worker).to have_received(:perform_async).with(issuable.id, user.id)
      end
    end

    context 'when issuable not an incident' do
      %i(issue merge_request).each do |issuable_type|
        let(:issuable) { build_stubbed(issuable_type) }

        it { is_expected.to be_nil }

        it 'does not set severity' do
          expect { update_severity }.not_to change(IssuableSeverity, :count)
        end

        it 'does not add a system note' do
          update_severity

          expect(system_note_worker).not_to have_received(:perform_async)
        end
      end
    end

    context 'when issuable is an incident' do
      let!(:issuable) { create(:incident) }

      context 'when issuable does not have issuable severity yet' do
        it 'creates new record' do
          expect { update_severity }.to change { IssuableSeverity.where(issue: issuable).count }.to(1)
        end

        it 'sets severity to specified value' do
          expect { update_severity }.to change { issuable.severity }.to('low')
        end

        it_behaves_like 'adds a system note'
      end

      context 'when issuable has an issuable severity' do
        let!(:issuable_severity) { create(:issuable_severity, issue: issuable, severity: 'medium') }

        it 'does not create new record' do
          expect { update_severity }.not_to change(IssuableSeverity, :count)
        end

        it 'updates existing issuable severity' do
          expect { update_severity }.to change { issuable_severity.severity }.to(severity)
        end

        it_behaves_like 'adds a system note'
      end

      context 'when severity value is unsupported' do
        let(:severity) { 'unsupported-severity' }

        it 'sets the severity to default value' do
          update_severity

          expect(issuable.issuable_severity.severity).to eq(IssuableSeverity::DEFAULT)
        end

        it_behaves_like 'adds a system note'
      end
    end
  end
end
