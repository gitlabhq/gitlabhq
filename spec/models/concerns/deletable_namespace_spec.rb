# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeletableNamespace, feature_category: :groups_and_projects do
  let(:model) do
    Class.new do
      include DeletableNamespace
    end
  end

  let(:record) { model.new }

  describe '#self_deletion_in_progress?' do
    it 'raises NotImplementedError by default' do
      expect { record.self_deletion_in_progress? }.to raise_error(NotImplementedError)
    end

    context 'when implemented' do
      before do
        model.send(:define_method, :self_deletion_in_progress?) do
          true
        end
      end

      it 'returns the implemented value' do
        expect(record.self_deletion_in_progress?).to be_truthy
      end
    end
  end

  describe '#self_deletion_scheduled_deletion_created_on & #self_deletion_scheduled?/#marked_for_deletion?' do
    context 'when record doesn not respond to marked_for_deletion_on' do
      it 'returns nil' do
        expect(record.self_deletion_scheduled_deletion_created_on).to be_nil
        expect(record.self_deletion_scheduled?).to be_falsy
        expect(record.marked_for_deletion?).to be_falsy
      end
    end

    context 'when record responds to marked_for_deletion_on', :freeze_time do
      before do
        model.send(:define_method, :marked_for_deletion_on) do
          Date.current
        end
      end

      it 'returns the date' do
        expect(record.self_deletion_scheduled_deletion_created_on).to eq(Date.current)
        expect(record.self_deletion_scheduled?).to be_truthy
        expect(record.marked_for_deletion?).to be_truthy
      end
    end
  end

  describe '#delayed_deletion_available?' do
    context 'when record doesn not respond to licensed_feature_available?' do
      it 'returns nil' do
        expect(record.delayed_deletion_available?).to be_falsy
      end
    end

    shared_examples 'delayed deletion available with #licensed_feature_available? defined' do |feature_available|
      context "when #licensed_feature_available? is #{feature_available}" do
        before do
          model.send(:define_method, :licensed_feature_available?) do |_feature_name|
            feature_available
          end
        end

        it "returns #{feature_available}" do
          expect(record).to receive(:licensed_feature_available?)
            .with(:adjourned_deletion_for_projects_and_groups)
            .and_call_original

          expect(record.delayed_deletion_available?).to be(feature_available)
        end
      end
    end

    it_behaves_like 'delayed deletion available with #licensed_feature_available? defined', true
    it_behaves_like 'delayed deletion available with #licensed_feature_available? defined', false
  end

  describe '#delayed_deletion_configured?' do
    context 'when Gitlab::CurrentSettings.deletion_adjourned_period > 0' do
      before do
        allow(Gitlab::CurrentSettings).to receive(:deletion_adjourned_period).and_return(30)
      end

      it 'returns true' do
        expect(record.delayed_deletion_configured?).to be_truthy
      end
    end

    context 'when deletion_adjourned_period is == 0' do
      before do
        allow(Gitlab::CurrentSettings).to receive(:deletion_adjourned_period).and_return(0)
      end

      it 'returns false' do
        expect(record.delayed_deletion_configured?).to be_falsy
      end
    end
  end

  describe '#all_scheduled_for_deletion_in_hierarchy_chain' do
    it 'returns an empty array' do
      expect(record.all_scheduled_for_deletion_in_hierarchy_chain).to be_empty
    end
  end

  describe '#first_scheduled_for_deletion_in_hierarchy_chain' do
    context 'when delayed deletion is not ready' do
      it 'returns nil' do
        expect(record.first_scheduled_for_deletion_in_hierarchy_chain).to be_nil
      end
    end

    context 'when delayed deletion is ready' do
      before do
        allow(record).to receive(:delayed_deletion_ready?).and_return(true)
      end

      context 'when self is scheduled for deletion' do
        before do
          allow(record).to receive(:self_deletion_scheduled?).and_return(true)
        end

        it 'returns self' do
          expect(record.first_scheduled_for_deletion_in_hierarchy_chain).to eq(record)
        end
      end

      context 'when self is not scheduled for deletion' do
        before do
          allow(record).to receive(:self_deletion_scheduled?).and_return(false)
        end

        it 'returns nil' do
          expect(record.first_scheduled_for_deletion_in_hierarchy_chain).to be_nil
        end
      end
    end
  end

  describe '#scheduled_for_deletion_in_hierarchy_chain?' do
    context 'when #first_scheduled_for_deletion_in_hierarchy_chain returns nil' do
      before do
        allow(record).to receive(:first_scheduled_for_deletion_in_hierarchy_chain).and_return(nil)
      end

      it 'returns false' do
        expect(record.scheduled_for_deletion_in_hierarchy_chain?).to be_falsy
      end
    end

    context 'when #first_scheduled_for_deletion_in_hierarchy_chain returns a record' do
      before do
        allow(record).to receive(:first_scheduled_for_deletion_in_hierarchy_chain).and_return(record)
      end

      it 'returns true' do
        expect(record.scheduled_for_deletion_in_hierarchy_chain?).to be_truthy
      end
    end
  end

  describe '#deletion_in_progress_or_scheduled_in_hierarchy_chain?' do
    context 'when #self_deletion_in_progress? is false' do
      before do
        allow(record).to receive(:self_deletion_in_progress?).and_return(false)
      end

      it 'returns false' do
        expect(record.deletion_in_progress_or_scheduled_in_hierarchy_chain?).to be_falsy
      end

      context 'when #scheduled_for_deletion_in_hierarchy_chain? is true' do
        before do
          allow(record).to receive(:scheduled_for_deletion_in_hierarchy_chain?).and_return(true)
        end

        it 'returns true' do
          expect(record.deletion_in_progress_or_scheduled_in_hierarchy_chain?).to be_truthy
        end
      end
    end

    context 'when #self_deletion_in_progress? is true' do
      before do
        allow(record).to receive(:self_deletion_in_progress?).and_return(true)
      end

      it 'returns true' do
        expect(record.deletion_in_progress_or_scheduled_in_hierarchy_chain?).to be_truthy
      end
    end
  end

  describe '#delayed_deletion_ready? & #adjourned_deletion?' do
    context 'when #delayed_deletion_available? is false' do
      before do
        allow(record).to receive(:delayed_deletion_available?).and_return(false)
      end

      it 'returns false' do
        expect(record.delayed_deletion_ready?).to be_falsy
        expect(record.adjourned_deletion?).to be_falsy
      end
    end

    context 'when #delayed_deletion_available? is true' do
      before do
        allow(record).to receive(:delayed_deletion_available?).and_return(true)
      end

      context 'when #delayed_deletion_configured? is false' do
        before do
          allow(record).to receive(:delayed_deletion_configured?).and_return(false)
        end

        it 'returns false' do
          expect(record.delayed_deletion_ready?).to be_falsy
          expect(record.adjourned_deletion?).to be_falsy
        end
      end

      context 'when #delayed_deletion_configured? is true' do
        before do
          allow(record).to receive(:delayed_deletion_configured?).and_return(true)
        end

        it 'returns true' do
          expect(record.delayed_deletion_ready?).to be_truthy
          expect(record.adjourned_deletion?).to be_truthy
        end
      end
    end
  end

  describe Namespace, pending: 'https://gitlab.com/gitlab-org/gitlab/-/work_items/527085' do
    describe '#self_deletion_in_progress?' do
      context 'when deleted_at is nil' do
        let_it_be(:namespace) { create(:namespace) }

        it 'returns false' do
          expect(namespace.self_deletion_in_progress?).to be_falsy
        end
      end

      context 'when deleted_at is not nil' do
        let_it_be(:namespace) { create(:namespace) { |n| n.deleted_at = Time.current } }

        it 'returns true' do
          expect(namespace.self_deletion_in_progress?).to be_truthy
        end
      end
    end
  end

  describe Project, pending: 'https://gitlab.com/gitlab-org/gitlab/-/work_items/527085' do
    describe '#self_deletion_in_progress?' do
      context 'when pending_delete is false' do
        let_it_be(:project) { create(:project, pending_delete: false) }

        it 'returns false' do
          expect(project.self_deletion_in_progress?).to be_falsy
        end
      end

      context 'when pending_delete is true' do
        let_it_be(:project) { create(:project, pending_delete: true) }

        it 'returns true' do
          expect(project.self_deletion_in_progress?).to be_truthy
        end
      end
    end
  end
end
