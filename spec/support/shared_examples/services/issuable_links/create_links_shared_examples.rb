# frozen_string_literal: true

RSpec.shared_examples 'issuable link creation' do
  describe '#execute' do
    subject { described_class.new(issuable, user, params).execute }

    context 'when the reference list is empty' do
      let(:params) do
        { issuable_references: [] }
      end

      it 'returns error' do
        is_expected.to eq(message: "No matching #{issuable_type} found. Make sure that you are adding a valid #{issuable_type} URL.", status: :error, http_status: 404)
      end
    end

    context 'when Issuable not found' do
      let(:params) do
        { issuable_references: ["##{non_existing_record_iid}"] }
      end

      it 'returns error' do
        is_expected.to eq(message: "No matching #{issuable_type} found. Make sure that you are adding a valid #{issuable_type} URL.", status: :error, http_status: 404)
      end

      it 'no relationship is created' do
        expect { subject }.not_to change { issuable_link_class.count }
      end
    end

    context 'when user has no permission to target issuable' do
      let(:params) do
        { issuable_references: [restricted_issuable.to_reference(issuable_parent)] }
      end

      it 'returns error' do
        if issuable_type == :issue
          is_expected.to eq(message: "Couldn't link #{issuable_type}. You must have at least the Reporter role in both projects.", status: :error, http_status: 403)
        else
          is_expected.to eq(message: "No matching #{issuable_type} found. Make sure that you are adding a valid #{issuable_type} URL.", status: :error, http_status: 404)
        end
      end

      it 'no relationship is created' do
        expect { subject }.not_to change { issuable_link_class.count }
      end
    end

    context 'source and target are the same issuable' do
      let(:params) do
        { issuable_references: [issuable.to_reference] }
      end

      it 'does not create notes' do
        expect(SystemNoteService).not_to receive(:relate_issuable)

        subject
      end

      it 'no relationship is created' do
        expect { subject }.not_to change { issuable_link_class.count }
      end
    end

    context 'when there is an issuable to relate' do
      let(:params) do
        { issuable_references: [issuable2.to_reference, issuable3.to_reference(issuable_parent)] }
      end

      it 'creates relationships' do
        expect { subject }.to change { issuable_link_class.count }.by(2)

        expect(issuable_link_class.find_by!(target: issuable2)).to have_attributes(source: issuable, link_type: 'relates_to')
        expect(issuable_link_class.find_by!(target: issuable3)).to have_attributes(source: issuable, link_type: 'relates_to')
      end

      it 'returns success status and created links', :aggregate_failures do
        expect(subject.keys).to match_array([:status, :created_references])
        expect(subject[:status]).to eq(:success)
        expect(subject[:created_references].map(&:target_id)).to match_array([issuable2.id, issuable3.id])
      end

      it 'creates notes' do
        # First two-way relation notes
        expect(SystemNoteService).to receive(:relate_issuable)
          .with(issuable, issuable2, user)
        expect(SystemNoteService).to receive(:relate_issuable)
          .with(issuable2, issuable, user)

        # Second two-way relation notes
        expect(SystemNoteService).to receive(:relate_issuable)
          .with(issuable, issuable3, user)
        expect(SystemNoteService).to receive(:relate_issuable)
          .with(issuable3, issuable, user)

        subject
      end
    end

    context 'when reference of any already related issue is present' do
      let(:params) do
        {
          issuable_references: [
            issuable_a.to_reference,
            issuable_b.to_reference
          ],
          link_type: IssueLink::TYPE_RELATES_TO
        }
      end

      it 'creates notes only for new relations' do
        expect(SystemNoteService).to receive(:relate_issuable).with(issuable, issuable_a, anything)
        expect(SystemNoteService).to receive(:relate_issuable).with(issuable_a, issuable, anything)
        expect(SystemNoteService).not_to receive(:relate_issuable).with(issuable, issuable_b, anything)
        expect(SystemNoteService).not_to receive(:relate_issuable).with(issuable_b, issuable, anything)

        subject
      end
    end

    context 'when there are invalid references' do
      let(:params) do
        { issuable_references: [issuable.to_reference, issuable_a.to_reference] }
      end

      it 'creates links only for valid references' do
        expect { subject }.to change { issuable_link_class.count }.by(1)
      end

      it 'returns error status' do
        expect(subject).to eq(
          status: :error,
          http_status: 422,
          message: "#{issuable.to_reference} cannot be added: cannot be related to itself"
        )
      end
    end
  end
end
