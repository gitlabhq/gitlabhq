# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuable::Callbacks::Labels, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :private, group: group) }
  let_it_be(:labels) { create_list(:label, 4, project: project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }

  let(:issuable) { create(:issue, project: project) }
  let(:current_user) { reporter }
  let(:params) { { add_label_ids: [labels.first.id] } }
  let(:callback) { described_class.new(issuable: issuable, current_user: current_user, params: params) }

  describe '#after_initialize' do
    it "sets the issuable's labels" do
      expect { callback.after_initialize }.to change { issuable.label_ids }.from([]).to([labels.first.id])
    end

    describe 'labels limit' do
      before do
        stub_const('Issue::MAX_NUMBER_OF_LABELS', 2)
      end

      context 'when adding labels within the limit' do
        let(:params) { { add_label_ids: labels.first(2).map(&:id) } }

        it 'sets the labels' do
          expect { callback.after_initialize }.to change { issuable.label_ids.size }.from(0).to(2)
        end
      end

      context 'when adding labels past the limit' do
        let(:params) { { add_label_ids: labels.first(3).map(&:id) } }

        it 'raises an error and does not persist any label links' do
          expect { callback.after_initialize }.to raise_error(
            Issuable::Callbacks::Base::Error, /Cannot add more than 2 labels/
          )

          expect(issuable.reload.label_ids).to be_empty
        end

        context 'when the limit_labels_per_work_item feature flag is disabled' do
          before do
            stub_feature_flags(limit_labels_per_work_item: false)
          end

          it 'does not enforce the limit' do
            expect { callback.after_initialize }.to change { issuable.label_ids.size }.from(0).to(3)
          end
        end
      end

      context 'when the issuable is already over the limit' do
        let(:issuable) { create(:issue, project: project, labels: labels.first(3)) }

        context 'when adding another label' do
          let(:params) { { add_label_ids: [labels.last.id] } }

          it 'raises an error' do
            expect { callback.after_initialize }.to raise_error(Issuable::Callbacks::Base::Error)
          end
        end

        context 'when removing a label' do
          let(:params) { { remove_label_ids: [labels.first.id] } }

          it 'allows the removal' do
            expect { callback.after_initialize }.to change { issuable.label_ids.size }.from(3).to(2)
          end
        end

        context 'when replacing with a smaller over-limit set' do
          let(:params) { { label_ids: labels.first(3).map(&:id) } }

          it 'allows the change' do
            expect { callback.after_initialize }.not_to raise_error
          end
        end
      end

      context 'when the issuable is a work item' do
        let(:issuable) { create(:work_item, :task, project: project) }
        let(:params) { { add_label_ids: labels.first(3).map(&:id) } }

        it 'raises an error' do
          expect { callback.after_initialize }.to raise_error(Issuable::Callbacks::Base::Error)
        end
      end

      context 'when the issuable is a merge request' do
        let_it_be(:developer) { create(:user, developer_of: project) }

        let(:issuable) { create(:merge_request, source_project: project) }
        let(:current_user) { developer }
        let(:params) { { add_label_ids: labels.first(3).map(&:id) } }

        it 'does not enforce the limit' do
          expect { callback.after_initialize }.to change { issuable.label_ids.size }.from(0).to(3)
        end
      end
    end
  end
end
