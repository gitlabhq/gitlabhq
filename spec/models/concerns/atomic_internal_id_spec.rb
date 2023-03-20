# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AtomicInternalId do
  let_it_be(:project) { create(:project) }
  let(:milestone) { build(:milestone, project: project) }
  let(:iid) { double('iid', to_i: 42) }
  let(:external_iid) { 100 }
  let(:scope_attrs) { { project: project } }
  let(:usage) { :milestones }

  describe '#save!' do
    context 'when IID is provided' do
      before do
        milestone.iid = external_iid
      end

      it 'tracks the value' do
        expect(milestone).to receive(:track_project_iid!)

        milestone.save!
      end

      context 'when importing' do
        before do
          milestone.importing = true
        end

        it 'does not track the value' do
          expect(milestone).not_to receive(:track_project_iid!)

          milestone.save!
        end
      end
    end
  end

  describe '#track_project_iid!' do
    subject { milestone.track_project_iid! }

    it 'tracks the present value' do
      milestone.iid = external_iid

      expect(InternalId).to receive(:track_greatest).once.with(milestone, scope_attrs, usage, external_iid, anything)
      expect(InternalId).not_to receive(:generate_next)

      subject
    end

    context 'when value is set by ensure_project_iid!' do
      it 'does not track the value' do
        expect(InternalId).not_to receive(:track_greatest)

        milestone.ensure_project_iid!
        subject
      end

      it 'tracks the iid for the scope that is actually present' do
        milestone.iid = external_iid

        expect(InternalId).to receive(:track_greatest).once.with(milestone, scope_attrs, usage, external_iid, anything)
        expect(InternalId).not_to receive(:generate_next)

        # group scope is not present here, the milestone does not have a group
        milestone.track_group_iid!
        subject
      end
    end
  end

  describe '#ensure_project_iid!' do
    subject { milestone.ensure_project_iid! }

    it 'generates a new value if non is present' do
      expect(InternalId).to receive(:generate_next).with(milestone, scope_attrs, usage, anything).and_return(iid)

      expect { subject }.to change { milestone.iid }.from(nil).to(iid.to_i)
    end

    it 'generates a new value if first set with iid= but later set to nil' do
      expect(InternalId).to receive(:generate_next).with(milestone, scope_attrs, usage, anything).and_return(iid)

      milestone.iid = external_iid
      milestone.iid = nil

      expect { subject }.to change { milestone.iid }.from(nil).to(iid.to_i)
    end
  end

  describe '#clear_scope_iid!' do
    context 'when no ensure_if condition is given' do
      it 'clears automatically set IIDs' do
        expect(milestone).to receive(:clear_project_iid!).and_call_original

        expect_iid_to_be_set_and_rollback(milestone)

        expect(milestone.iid).to be_nil
      end

      it 'does not clear manually set IIDS' do
        milestone.iid = external_iid

        expect(milestone).to receive(:clear_project_iid!).and_call_original

        expect_iid_to_be_set_and_rollback(milestone)

        expect(milestone.iid).to eq(external_iid)
      end
    end

    context 'when an ensure_if condition is given' do
      let(:test_class) do
        Class.new(ApplicationRecord) do
          include AtomicInternalId
          include Importable

          self.table_name = :milestones

          belongs_to :project

          has_internal_id :iid, scope: :project, track_if: -> { !importing }, ensure_if: -> { !importing }

          def self.name
            'TestClass'
          end
        end
      end

      let(:instance) { test_class.new(milestone.attributes) }

      context 'when the ensure_if condition evaluates to true' do
        it 'clears automatically set IIDs' do
          expect(instance).to receive(:clear_project_iid!).and_call_original

          expect_iid_to_be_set_and_rollback(instance)

          expect(instance.iid).to be_nil
        end

        it 'does not clear manually set IIDs' do
          instance.iid = external_iid

          expect(instance).to receive(:clear_project_iid!).and_call_original

          expect_iid_to_be_set_and_rollback(instance)

          expect(instance.iid).to eq(external_iid)
        end
      end

      context 'when the ensure_if condition evaluates to false' do
        before do
          instance.importing = true
        end

        it 'does not clear IIDs' do
          instance.iid = external_iid

          expect(instance).not_to receive(:clear_project_iid!)

          expect_iid_to_be_set_and_rollback(instance)

          expect(instance.iid).to eq(external_iid)
        end
      end
    end

    def expect_iid_to_be_set_and_rollback(instance)
      ActiveRecord::Base.transaction(requires_new: true) do
        instance.save!

        expect(instance.iid).not_to be_nil

        raise ActiveRecord::Rollback
      end
    end
  end

  describe '#validate_scope_iid_exists!' do
    let(:test_class) do
      Class.new(ApplicationRecord) do
        include AtomicInternalId
        include Importable

        self.table_name = :milestones

        belongs_to :project

        def self.name
          'TestClass'
        end
      end
    end

    let(:instance) { test_class.new(milestone.attributes) }

    before do
      test_class.has_internal_id :iid, scope: :project, presence: presence, ensure_if: -> { !importing }

      instance.importing = true
    end

    context 'when the presence flag is set' do
      let(:presence) { true }

      it 'raises an error for blank iids on create' do
        expect do
          instance.save!
        end.to raise_error(described_class::MissingValueError, 'iid was unexpectedly blank!')
      end

      it 'raises an error for blank iids on update' do
        instance.iid = 100
        instance.save!

        instance.iid = nil

        expect do
          instance.save!
        end.to raise_error(described_class::MissingValueError, 'iid was unexpectedly blank!')
      end
    end

    context 'when the presence flag is not set' do
      let(:presence) { false }

      it 'does not raise an error for blank iids on create' do
        expect { instance.save! }.not_to raise_error
      end

      it 'does not raise an error for blank iids on update' do
        instance.iid = 100
        instance.save!

        instance.iid = nil

        expect { instance.save! }.not_to raise_error
      end
    end
  end

  describe '.with_project_iid_supply' do
    it 'supplies a stream of iid values' do
      expect do
        ::Milestone.with_project_iid_supply(milestone.project) do |supply|
          4.times { supply.next_value }
        end
      end.to change { InternalId.find_by(project: milestone.project, usage: :milestones)&.last_value.to_i }.by(4)
    end
  end

  describe '.track_namespace_iid!' do
    it 'tracks the present value' do
      expect do
        ::Issue.track_namespace_iid!(milestone.project.project_namespace, external_iid)
      end.to change {
        InternalId.find_by(namespace: milestone.project.project_namespace, usage: :issues)&.last_value.to_i
      }.to(external_iid)
    end
  end

  context 'when transitioning a model from one scope to another' do
    let!(:issue) { build(:issue, project: project) }
    let(:old_issue_model) do
      Class.new(ApplicationRecord) do
        include AtomicInternalId

        self.table_name = :issues

        belongs_to :project
        belongs_to :namespace

        has_internal_id :iid, scope: :project

        def self.name
          'TestClassA'
        end
      end
    end

    let(:old_issue_instance) { old_issue_model.new(issue.attributes) }
    let(:new_issue_instance) { Issue.new(issue.attributes) }

    it 'generates the iid on the new scope' do
      # set a random iid, just so that it does not start at 1
      old_issue_instance.iid = 123
      old_issue_instance.save!

      # creating a new old_issue_instance increments the iid.
      expect { old_issue_model.new(issue.attributes).save! }.to change {
        InternalId.find_by(project: project, usage: :issues)&.last_value.to_i
      }.from(123).to(124).and(not_change { InternalId.count })

      # creating a new Issue creates a new record in internal_ids, scoped to the namespace.
      # Given the Issue#has_internal_id -> init definition the internal_ids#last_value would be the
      # maximum between the old iid value in internal_ids, scoped to the project and max(iid) value from issues
      # table by namespace_id.
      # see Issue#has_internal_id
      expect { new_issue_instance.save! }.to change {
        InternalId.find_by(namespace: project.project_namespace, usage: :issues)&.last_value.to_i
      }.to(125).and(change { InternalId.count }.by(1))

      # transition back to project scope would generate overlapping IIDs and raise a duplicate key value error, unless
      # we cleanup the issues usage scoped to the project first
      expect { old_issue_model.new(issue.attributes).save! }.to raise_error(ActiveRecord::RecordNotUnique)

      # delete issues usage scoped to te project
      InternalId.where(project: project, usage: :issues).delete_all

      expect { old_issue_model.new(issue.attributes).save! }.to change {
        InternalId.find_by(project: project, usage: :issues)&.last_value.to_i
      }.to(126).and(change { InternalId.count }.by(1))
    end
  end

  context 'when models is scoped to namespace and does not have an init proc' do
    let!(:issue) { build(:issue, namespace: create(:group)) }

    let(:issue_model) do
      Class.new(ApplicationRecord) do
        include AtomicInternalId

        self.table_name = :issues

        belongs_to :project
        belongs_to :namespace

        has_internal_id :iid, scope: :namespace

        def self.name
          'TestClass'
        end
      end
    end

    let(:model_instance) { issue_model.new(issue.attributes) }

    it 'generates the iid on the new scope' do
      expect { model_instance.save! }.to change {
        InternalId.find_by(namespace: model_instance.namespace, usage: :issues)&.last_value.to_i
      }.to(1).and(change { InternalId.count }.by(1))
    end

    it 'supplies a stream of iid values' do
      expect do
        issue_model.with_namespace_iid_supply(model_instance.namespace) do |supply|
          4.times { supply.next_value }
        end
      end.to change { InternalId.find_by(namespace: model_instance.namespace, usage: :issues)&.last_value.to_i }.by(4)
    end
  end
end
