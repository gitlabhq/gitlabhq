# frozen_string_literal: true

RSpec.shared_examples 'issuable link creation' do |use_references: true|
  let(:items_param) { use_references ? :issuable_references : :target_issuable }
  let(:response_keys) { [:status, :created_references] }
  let(:async_notes) { false }
  let(:already_assigned_error_msg) { "#{issuable_type.capitalize}(s) already assigned" }
  let(:permission_error_status) { issuable_type == :issue ? 403 : 404 }
  let(:noteable) { issuable }
  let(:noteable2) { issuable2 }
  let(:noteable3) { issuable3 }
  let(:noteable_a) { issuable_a }
  let(:noteable_b) { issuable_b }
  let(:noteable_link_class) { issuable_link_class }

  let(:no_found_error_msg) do
    "No matching #{issuable_type} found. Make sure that you are adding a valid #{issuable_type} URL."
  end

  describe '#execute' do
    subject { described_class.new(issuable, user, params).execute }

    context 'when the items list is empty' do
      let(:params) { set_params([]) }

      it 'returns error' do
        is_expected.to eq(message: no_found_error_msg, status: :error, http_status: 404)
      end
    end

    context 'when Issuable not found' do
      let(:params) do
        { issuable_references: ["##{non_existing_record_iid}"] }
      end

      it 'returns error' do
        is_expected.to eq(message: no_found_error_msg, status: :error, http_status: 404)
      end

      it 'no relationship is created' do
        expect { subject }.not_to change { issuable_link_class.count }
      end
    end

    context 'when user has no permission to target issuable' do
      let(:params) { set_params([restricted_issuable]) }

      it 'returns error' do
        is_expected.to eq(message: no_found_error_msg, status: :error, http_status: 404)
      end

      it 'no relationship is created' do
        expect { subject }.not_to change { issuable_link_class.count }
      end
    end

    context 'source and target are the same issuable' do
      let(:params) { set_params([issuable]) }

      it 'does not create notes' do
        if async_notes
          expect(Issuable::RelatedLinksCreateWorker).not_to receive(:perform_async)
        else
          expect(SystemNoteService).not_to receive(:relate_issuable)
        end

        subject
      end

      it 'no relationship is created' do
        expect { subject }.not_to change { issuable_link_class.count }
      end
    end

    context 'when there is an issuable to relate' do
      let(:params) { set_params([issuable2, issuable3]) }

      it 'creates relationships' do
        expect { subject }.to change { issuable_link_class.count }.by(2)

        expect(issuable_link_class.find_by!(target: issuable2)).to have_attributes(source: issuable, link_type: 'relates_to')
        expect(issuable_link_class.find_by!(target: issuable3)).to have_attributes(source: issuable, link_type: 'relates_to')
      end

      it 'returns success status and created links', :aggregate_failures do
        expect(subject.keys).to match_array(response_keys)
        expect(subject[:status]).to eq(:success)
        expect(subject[:created_references].map(&:target_id)).to match_array([issuable2.id, issuable3.id])
      end

      it 'creates notes' do
        if async_notes
          expect(Issuable::RelatedLinksCreateWorker).to receive(:perform_async) do |args|
            expect(args).to eq(
              {
                issuable_class: noteable.class.name,
                issuable_id: noteable.id,
                link_ids: noteable_link_class.where(source: noteable).last(2).pluck(:id),
                link_type: 'relates_to',
                user_id: user.id
              }
            )
          end
        else
          # First two-way relation notes
          expect(SystemNoteService).to receive(:relate_issuable).with(noteable, noteable2, user)
          expect(SystemNoteService).to receive(:relate_issuable).with(noteable2, noteable, user)

          # Second two-way relation notes
          expect(SystemNoteService).to receive(:relate_issuable).with(noteable, noteable3, user)
          expect(SystemNoteService).to receive(:relate_issuable).with(noteable3, noteable, user)
        end

        subject
      end
    end

    context 'when reference of any already related issue is present' do
      let(:params) { set_params([issuable_a, issuable_b]) }

      it 'creates notes only for new relations' do
        if async_notes
          expect(Issuable::RelatedLinksCreateWorker).to receive(:perform_async) do |args|
            expect(args).to eq(
              {
                issuable_class: noteable.class.name,
                issuable_id: noteable.id,
                link_ids: noteable_link_class.where(source: noteable).last(1).pluck(:id),
                link_type: 'relates_to',
                user_id: user.id
              }
            )
          end
        else
          expect(SystemNoteService).to receive(:relate_issuable).with(noteable, noteable_a, anything)
          expect(SystemNoteService).to receive(:relate_issuable).with(noteable_a, noteable, anything)
          expect(SystemNoteService).not_to receive(:relate_issuable).with(noteable, noteable_b, anything)
          expect(SystemNoteService).not_to receive(:relate_issuable).with(noteable_b, noteable, anything)
        end

        subject
      end
    end

    context 'when reference of all related issue are present' do
      let(:params) { set_params([issuable_b]) }

      it 'returns error status' do
        expect(subject).to eq(status: :error, http_status: 409, message: already_assigned_error_msg)
      end
    end
  end

  def set_params(items)
    items_list = items_param == :issuable_references ? items.map { |item| item.to_reference(issuable_parent) } : items

    { items_param => items_list }
  end
end
