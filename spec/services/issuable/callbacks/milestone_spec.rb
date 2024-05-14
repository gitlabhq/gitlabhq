# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuable::Callbacks::Milestone, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :private, group: group) }
  let_it_be(:project_milestone) { create(:milestone, project: project) }
  let_it_be(:group_milestone) { create(:milestone, group: group) }
  let_it_be(:reporter) do
    create(:user, reporter_of: project)
  end

  let(:issuable) { build(:issue, project: project) }
  let(:current_user) { reporter }
  let(:params) { { milestone_id: project_milestone.id } }
  let(:callback) { described_class.new(issuable: issuable, current_user: current_user, params: params) }

  describe '#after_initialize' do
    it "sets the issuable's milestone" do
      expect { callback.after_initialize }.to change { issuable.milestone }.from(nil).to(project_milestone)
    end

    context 'when assigning a group milestone' do
      let(:params) { { milestone_id: group_milestone.id } }

      it "sets the issuable's milestone" do
        expect { callback.after_initialize }.to change { issuable.milestone }.from(nil).to(group_milestone)
      end
    end

    context 'when assigning a group milestone outside the project ancestors' do
      let(:another_group_milestone) { create(:milestone, group: create(:group)) }
      let(:params) { { milestone_id: another_group_milestone.id } }

      it "does not change the issuable's milestone" do
        expect { callback.after_initialize }.not_to change { issuable.milestone }
      end
    end

    context 'when user is not allowed to set issuable metadata' do
      let(:current_user) { create(:user) }

      it "does not change the issuable's milestone" do
        expect { callback.after_initialize }.not_to change { issuable.milestone }
      end
    end

    context 'when unsetting a milestone' do
      let(:issuable) { create(:issue, project: project, milestone: project_milestone) }

      context 'when milestone_id is nil' do
        let(:params) { { milestone_id: nil } }

        it "unsets the issuable's milestone" do
          expect { callback.after_initialize }.to change { issuable.milestone }.from(project_milestone).to(nil)
        end
      end

      context 'when milestone_id is an empty string' do
        let(:params) { { milestone_id: '' } }

        it "unsets the issuable's milestone" do
          expect { callback.after_initialize }.to change { issuable.milestone }.from(project_milestone).to(nil)
        end
      end

      context 'when milestone_id is 0' do
        let(:params) { { milestone_id: '0' } }

        it "unsets the issuable's milestone" do
          expect { callback.after_initialize }.to change { issuable.milestone }.from(project_milestone).to(nil)
        end
      end

      context "when milestone_id is '0'" do
        let(:params) { { milestone_id: 0 } }

        it "unsets the issuable's milestone" do
          expect { callback.after_initialize }.to change { issuable.milestone }.from(project_milestone).to(nil)
        end
      end

      context 'when milestone_id is not given' do
        let(:params) { {} }

        it "does not unset the issuable's milestone" do
          expect { callback.after_initialize }.not_to change { issuable.milestone }
        end
      end

      context 'when new type does not support milestones' do
        let(:params) { { excluded_in_new_type: true } }

        it "unsets the issuable's milestone" do
          expect { callback.after_initialize }.to change { issuable.milestone }.from(project_milestone).to(nil)
        end
      end
    end
  end
end
