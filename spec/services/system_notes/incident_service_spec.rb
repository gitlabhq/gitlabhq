# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::SystemNotes::IncidentService do
  let_it_be(:author) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:noteable) { create(:incident, project: project) }
  let_it_be(:issuable_severity) { create(:issuable_severity, issue: noteable, severity: :medium) }

  describe '#change_incident_severity' do
    subject(:change_severity) { described_class.new(noteable: noteable, project: project, author: author).change_incident_severity }

    before do
      allow(Gitlab::AppLogger).to receive(:error).and_call_original
    end

    it_behaves_like 'a system note' do
      let(:action) { 'severity' }
    end

    IssuableSeverity.severities.keys.each do |severity|
      context "with #{severity} severity" do
        before do
          issuable_severity.update!(severity: severity)
        end

        it 'has the appropriate message' do
          severity_label = IssuableSeverity::SEVERITY_LABELS.fetch(severity.to_sym)

          expect(change_severity.note).to eq("changed the severity to **#{severity_label}**")
        end
      end
    end

    context 'when severity is invalid' do
      let(:invalid_severity) { 'invalid-severity' }

      before do
        allow(noteable).to receive(:severity).and_return(invalid_severity)
      end

      it 'does not create system note' do
        expect { change_severity }.not_to change { noteable.notes.count }
      end

      it 'writes error to logs' do
        change_severity

        expect(Gitlab::AppLogger).to have_received(:error).with(
          message: 'Cannot create a system note for severity change',
          noteable_class: noteable.class.to_s,
          noteable_id: noteable.id,
          severity: invalid_severity
        )
      end
    end
  end
end
