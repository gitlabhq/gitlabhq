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

    context 'when downtier_delayed_deletion feature flag is disabled' do
      before do
        stub_feature_flags(downtier_delayed_deletion: false)
      end

      it 'returns false', :aggregate_failures do
        expect(project).not_to receive(:adjourned_deletion_configured?)
        expect(project.adjourned_deletion?).to be false
      end
    end
  end

  describe '#adjourned_deletion_configured?' do
    context 'when deletion_adjourned_period is zero' do
      before do
        stub_application_setting(deletion_adjourned_period: 0)
      end

      it 'returns false' do
        expect(project.adjourned_deletion_configured?).to be false
      end
    end

    context 'when deletion_adjourned_period is positive' do
      before do
        stub_application_setting(deletion_adjourned_period: 7)
      end

      context 'for groups' do
        let(:group) { build(:group) }

        it 'returns true' do
          expect(group.adjourned_deletion_configured?).to be true
        end
      end

      context 'when it is a personal project' do
        before do
          allow(project).to receive(:personal?).and_return(true)
        end

        it 'returns false' do
          expect(project.adjourned_deletion_configured?).to be false
        end
      end

      context 'when it is not a personal project' do
        before do
          allow(project).to receive(:personal?).and_return(false)
        end

        it 'returns true' do
          expect(project.adjourned_deletion_configured?).to be true
        end

        context 'when downtier_delayed_deletion feature flag is disabled' do
          before do
            stub_feature_flags(downtier_delayed_deletion: false)
          end

          it 'returns false' do
            expect(project.adjourned_deletion_configured?).to be false
          end
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

      context 'when downtier_delayed_deletion feature flag is disabled' do
        before do
          stub_feature_flags(downtier_delayed_deletion: false)
        end

        it 'returns false' do
          expect(project.marked_for_deletion?).to be false
        end
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

      context 'when downtier_delayed_deletion feature flag is disabled' do
        before do
          stub_feature_flags(downtier_delayed_deletion: false)
        end

        it 'returns nil' do
          expect(project.self_or_ancestor_marked_for_deletion).to be_nil
        end
      end
    end

    context 'when the project is not marked for deletion' do
      context 'when an ancestor is marked for deletion' do
        let_it_be(:group) { create(:group_with_deletion_schedule) }
        let_it_be(:project) { create(:project, group: group) }

        it 'returns the first ancestor marked for deletion' do
          expect(project.self_or_ancestor_marked_for_deletion).to eq(group)
        end

        context 'when downtier_delayed_deletion feature flag is disabled' do
          before do
            stub_feature_flags(downtier_delayed_deletion: false)
          end

          it 'returns nil' do
            expect(project.self_or_ancestor_marked_for_deletion).to be_nil
          end
        end
      end

      context 'when no ancestor is marked for deletion' do
        it 'returns nil' do
          expect(project.self_or_ancestor_marked_for_deletion).to be_nil
        end
      end
    end
  end

  describe '#permanent_deletion_date' do
    let(:date) { Time.current }
    let(:adjourned_period) { 7 }

    before do
      stub_application_setting(deletion_adjourned_period: adjourned_period)
    end

    it 'returns the date plus the configured adjourned period in days', :freeze_time do
      expected_date = date + adjourned_period.days
      expect(project.permanent_deletion_date(date)).to eq(expected_date)
    end
  end
end
