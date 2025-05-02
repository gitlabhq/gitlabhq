# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::AdjournedDeletable, feature_category: :groups_and_projects do
  let(:project) { build(:project) }

  describe '#adjourned_deletion?' do
    it 'returns the result of adjourned_deletion_configured?', :aggregate_failures do
      expect(project).to receive(:adjourned_deletion_configured?).and_return(true)
      expect(project.adjourned_deletion?).to be true

      expect(project).to receive(:adjourned_deletion_configured?).and_return(false)
      expect(project.adjourned_deletion?).to be false
    end
  end

  describe '#adjourned_deletion_configured?' do
    %w[group project].each do |context|
      context "for #{context}" do
        subject(:adjourned_deletion_configured) { build(context).adjourned_deletion_configured? }

        context 'when deletion_adjourned_period is zero' do
          before do
            stub_application_setting(deletion_adjourned_period: 0)
          end

          it { is_expected.to be false }
        end

        context 'when deletion_adjourned_period is positive' do
          before do
            stub_application_setting(deletion_adjourned_period: 7)
          end

          it { is_expected.to be true }
        end
      end
    end
  end

  describe '#marked_for_deletion?' do
    context 'when marked_for_deletion_at is present' do
      before do
        project.marked_for_deletion_at = Time.current
      end

      it 'returns true' do
        expect(project.marked_for_deletion?).to be true
      end
    end

    context 'when marked_for_deletion_at is nil' do
      before do
        project.marked_for_deletion_at = nil
      end

      it 'returns false' do
        expect(project.marked_for_deletion?).to be false
      end
    end
  end

  describe '#self_or_ancestor_marked_for_deletion' do
    let_it_be(:group) { create(:group) }
    let_it_be_with_reload(:project) { create(:project, group: group) }

    context 'when the project is marked for deletion' do
      before do
        project.update!(marked_for_deletion_on: Time.current)
      end

      it 'returns self' do
        expect(project.self_or_ancestor_marked_for_deletion).to eq(project)
      end
    end

    context 'when the project is not marked for deletion' do
      context 'when an ancestor is marked for deletion' do
        let_it_be(:group) { create(:group_with_deletion_schedule) }
        let_it_be(:project) { create(:project, group: group) }

        it 'returns the first ancestor marked for deletion' do
          expect(project.self_or_ancestor_marked_for_deletion).to eq(group)
        end
      end

      context 'when no ancestor is marked for deletion' do
        it 'returns nil' do
          expect(project.self_or_ancestor_marked_for_deletion).to be_nil
        end
      end
    end
  end
end
