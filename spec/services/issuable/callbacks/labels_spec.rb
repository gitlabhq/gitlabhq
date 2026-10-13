# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuable::Callbacks::Labels, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :private, group: group) }
  let_it_be(:labels) { create_list(:label, 4, project: project) }
  let_it_be(:archived_label) { create(:label, :archived, project: project) }
  let_it_be(:another_archived_label) { create(:label, :archived, project: project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }

  let(:existing_labels) { [] }
  let(:issuable) { create(:issue, project: project, labels: existing_labels) }
  let(:current_user) { reporter }
  let(:params) { { add_label_ids: [labels.first.id] } }
  let(:callback) { described_class.new(issuable: issuable, current_user: current_user, params: params) }

  subject(:apply_labels) { callback.after_initialize }

  describe '#after_initialize' do
    it "sets the issuable's labels" do
      expect { apply_labels }.to change { issuable.label_ids }.from([]).to([labels.first.id])
    end

    describe 'archived labels' do
      context 'with add_label_ids' do
        let(:params) { { add_label_ids: [labels.first.id, archived_label.id] } }

        it 'adds active labels and rejects archived labels' do
          apply_labels

          expect(issuable.reload.labels).to contain_exactly(labels.first)
        end
      end

      context 'with add_labels' do
        let(:params) { { add_labels: [labels.first.title, archived_label.title] } }

        it 'adds active labels and rejects archived labels' do
          apply_labels

          expect(issuable.reload.labels).to contain_exactly(labels.first)
        end

        context 'when a new label title fails validation' do
          let(:params) { { add_labels: [labels.first.title, 'a' * 256] } }

          it 'adds only the valid label' do
            apply_labels

            expect(issuable.reload.labels).to contain_exactly(labels.first)
          end
        end
      end

      context 'with label_ids' do
        let(:existing_labels) { [labels.first, archived_label] }
        let(:params) do
          { label_ids: [archived_label.id, labels.second.id, another_archived_label.id] }
        end

        it 'replaces active labels, preserves existing archived labels, and rejects new archived labels' do
          apply_labels

          expect(issuable.reload.labels).to contain_exactly(archived_label, labels.second)
        end
      end

      context 'with remove_label_ids' do
        let(:existing_labels) { [labels.first, archived_label] }
        let(:params) { { remove_label_ids: [archived_label.id] } }

        it 'removes existing archived labels' do
          apply_labels

          expect(issuable.reload.labels).to contain_exactly(labels.first)
        end
      end

      context 'with add_label_ids and remove_label_ids' do
        let(:existing_labels) { [archived_label] }
        let(:params) do
          { add_label_ids: [labels.first.id], remove_label_ids: [archived_label.id] }
        end

        it 'removes the archived label and adds the active label' do
          apply_labels

          expect(issuable.reload.labels).to contain_exactly(labels.first)
        end
      end

      context 'when creating an issuable' do
        let(:issuable) { build(:issue, project: project, author: current_user) }
        let(:params) { { label_ids: [labels.first.id, archived_label.id] } }

        it 'adds active labels and rejects archived labels' do
          apply_labels

          expect(issuable.labels).to contain_exactly(labels.first)
        end
      end

      context 'with locked labels on a merged merge request' do
        let_it_be(:developer) { create(:user, developer_of: project) }
        let_it_be(:archived_locked_label) do
          create(:label, :archived, project: project, lock_on_merge: true)
        end

        let(:current_user) { developer }
        let(:issuable) do
          create(:merge_request, :merged, source_project: project, target_project: project, labels: existing_labels)
        end

        context 'when the archived locked label is newly requested' do
          let(:existing_labels) { [labels.first] }
          let(:params) { { add_label_ids: [archived_locked_label.id] } }

          it 'does not add it' do
            expect(Ability.allowed?(current_user, :set_merge_request_metadata, issuable)).to be(true)
            expect(issuable.supports_lock_on_merge?).to be(true)

            apply_labels

            expect(issuable.reload.labels).to contain_exactly(labels.first)
          end
        end

        context 'when the archived locked label already exists' do
          let(:existing_labels) { [archived_locked_label] }
          let(:params) { { add_label_ids: [labels.first.id] } }

          it 'preserves it and adds an active label' do
            expect(Ability.allowed?(current_user, :set_merge_request_metadata, issuable)).to be(true)
            expect(issuable.supports_lock_on_merge?).to be(true)

            apply_labels

            expect(issuable.reload.labels).to contain_exactly(archived_locked_label, labels.first)
          end
        end

        context 'when removal of the existing archived locked label is requested' do
          let(:existing_labels) { [archived_locked_label, labels.first] }
          let(:params) { { remove_label_ids: [archived_locked_label.id] } }

          it 'restores it' do
            expect(Ability.allowed?(current_user, :set_merge_request_metadata, issuable)).to be(true)
            expect(issuable.supports_lock_on_merge?).to be(true)

            apply_labels

            expect(issuable.reload.labels).to contain_exactly(archived_locked_label, labels.first)
          end
        end
      end
    end

    describe 'labels limit' do
      before do
        stub_const('Issue::MAX_NUMBER_OF_LABELS', 2)
      end

      context 'when adding labels within the limit' do
        let(:params) { { add_label_ids: labels.first(2).map(&:id) } }

        it 'sets the labels' do
          expect { apply_labels }.to change { issuable.label_ids.size }.from(0).to(2)
        end
      end

      context 'when an archived label would otherwise exceed the limit' do
        let(:existing_labels) { labels.first(2) }
        let(:params) { { add_labels: archived_label.title } }

        it 'rejects the archived label before validating the limit' do
          expect { apply_labels }.not_to raise_error

          expect(issuable.reload.labels).to match_array(existing_labels)
        end
      end

      context 'when adding labels past the limit' do
        let(:params) { { add_label_ids: labels.first(3).map(&:id) } }

        it 'raises an error and does not persist any label links' do
          expect { apply_labels }.to raise_error(
            Issuable::Callbacks::Base::Error, /Cannot add more than 2 labels/
          )

          expect(issuable.reload.label_ids).to be_empty
        end

        context 'when the limit_labels_per_work_item feature flag is disabled' do
          before do
            stub_feature_flags(limit_labels_per_work_item: false)
          end

          it 'does not enforce the limit' do
            expect { apply_labels }.to change { issuable.label_ids.size }.from(0).to(3)
          end
        end
      end

      context 'when the issuable is already over the limit' do
        let(:issuable) { create(:issue, project: project, labels: labels.first(3)) }

        context 'when adding another label' do
          let(:params) { { add_label_ids: [labels.last.id] } }

          it 'raises an error' do
            expect { apply_labels }.to raise_error(Issuable::Callbacks::Base::Error)
          end
        end

        context 'when removing a label' do
          let(:params) { { remove_label_ids: [labels.first.id] } }

          it 'allows the removal' do
            expect { apply_labels }.to change { issuable.label_ids.size }.from(3).to(2)
          end
        end

        context 'when replacing with a smaller over-limit set' do
          let(:params) { { label_ids: labels.first(3).map(&:id) } }

          it 'allows the change' do
            expect { apply_labels }.not_to raise_error
          end
        end
      end

      context 'when the issuable is a work item' do
        let(:issuable) { create(:work_item, :task, project: project) }
        let(:params) { { add_label_ids: labels.first(3).map(&:id) } }

        it 'raises an error' do
          expect { apply_labels }.to raise_error(Issuable::Callbacks::Base::Error)
        end
      end

      context 'when the issuable is a merge request' do
        let_it_be(:developer) { create(:user, developer_of: project) }

        let(:issuable) { create(:merge_request, source_project: project) }
        let(:current_user) { developer }
        let(:params) { { add_label_ids: labels.first(3).map(&:id) } }

        it 'does not enforce the limit' do
          expect { apply_labels }.to change { issuable.label_ids.size }.from(0).to(3)
        end
      end
    end
  end
end
