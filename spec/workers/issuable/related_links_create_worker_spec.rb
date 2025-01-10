# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuable::RelatedLinksCreateWorker, feature_category: :portfolio_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:issuable) { create(:work_item, :task, project: project) }
  let_it_be(:target1) { create(:work_item, :task, project: project) }
  let_it_be(:target2) { create(:work_item, :task, project: project) }
  let_it_be(:link1) { create(:work_item_link, source: issuable, target: target1) }
  let_it_be(:link2) { create(:work_item_link, source: issuable, target: target2) }
  let_it_be(:user) { create(:user, reporter_of: project) }

  let(:params) do
    {
      issuable_class: issuable.class.name,
      issuable_id: issuable.id,
      link_ids: [link1.id, link2.id],
      link_type: 'relates_to',
      user_id: user.id
    }.transform_keys(&:to_s)
  end

  before_all do
    # Ensure support bot user is created so creation doesn't count towards query limit
    # and we don't try to obtain an exclusive lease within a transaction.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/509629
    Users::Internal.support_bot_id
  end

  subject { described_class.new.perform(params) }

  describe '#perform' do
    it 'calls #relate_issuable on SystemNoteService' do
      # One note for the issuable that references all the linked issuables
      expect(SystemNoteService).to receive(:relate_issuable).with(issuable, [target1, target2], user)

      # One note for each linked issuable referencing the source issuable
      expect(SystemNoteService).to receive(:relate_issuable).with(target1, issuable, user)
      expect(SystemNoteService).to receive(:relate_issuable).with(target2, issuable, user)

      subject
    end

    it 'creates correct notes' do
      subject

      expect(issuable.notes.last.note)
        .to eq("marked this task as related to #{target1.to_reference} and #{target2.to_reference}")
      expect(target1.notes.last.note).to eq("marked this task as related to #{issuable.to_reference}")
      expect(target2.notes.last.note).to eq("marked this task as related to #{issuable.to_reference}")
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { params }
    end

    context 'when params contain errors' do
      it 'does nothing when user is not found' do
        params['user_id'] = non_existing_record_id

        expect(Sidekiq.logger).not_to receive(:error)
        expect { subject }.not_to change { Note.count }
      end

      it 'does nothing when issuable is not found' do
        params['issuable_id'] = non_existing_record_id

        expect(Sidekiq.logger).not_to receive(:error)
        expect { subject }.not_to change { Note.count }
      end

      it 'does nothing when links are not found' do
        params['link_ids'] = [non_existing_record_id]

        expect(Sidekiq.logger).not_to receive(:error)
        expect { subject }.not_to change { Note.count }
      end

      it 'logs error when issuable_class is invalid' do
        params['issuable_class'] = 'FooBar'

        expect(Sidekiq.logger).to receive(:error).with({
          worker: described_class.to_s,
          message: "Failed to complete job (user_id:#{user.id}, issuable_id:#{issuable.id}, " \
                   "issuable_class:FooBar): Unknown class 'FooBar'"
        })

        subject
      end

      context 'when notes are not created' do
        before do
          allow(SystemNoteService).to receive(:relate_issuable).with(target1, issuable, user).and_call_original
          allow(SystemNoteService).to receive(:relate_issuable).with(target2, issuable, user).and_return(nil)
          allow(SystemNoteService).to receive(:relate_issuable).with(issuable, [target1, target2], user).and_return(nil)
        end

        it 'logs error' do
          expect(Sidekiq.logger).to receive(:error).with({
            worker: described_class.to_s,
            message: "Failed to complete job (user_id:#{user.id}, issuable_id:#{issuable.id}, " \
                     "issuable_class:#{issuable.class.name}): Could not create notes: " \
                     "{noteable_id: #{target2.id}, reference_ids: [#{issuable.id}]}, " \
                     "{noteable_id: #{issuable.id}, reference_ids: #{[target1.id, target2.id]}}"
          })

          subject
        end
      end
    end
  end
end
