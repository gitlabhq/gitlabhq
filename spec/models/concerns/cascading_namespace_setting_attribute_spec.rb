# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NamespaceSetting, 'CascadingNamespaceSettingAttribute' do
  let(:group) { create(:group) }
  let(:subgroup) { create(:group, parent: group) }

  def group_settings
    group.namespace_settings
  end

  def subgroup_settings
    subgroup.namespace_settings
  end

  describe '#delayed_project_removal' do
    subject(:delayed_project_removal) { subgroup_settings.delayed_project_removal }

    context 'when there is no parent' do
      context 'and the value is not nil' do
        before do
          group_settings.update!(delayed_project_removal: true)
        end

        it 'returns the local value' do
          expect(group_settings.delayed_project_removal).to eq(true)
        end
      end

      context 'and the value is nil' do
        before do
          group_settings.update!(delayed_project_removal: nil)
          stub_application_setting(delayed_project_removal: false)
        end

        it 'returns the application settings value' do
          expect(group_settings.delayed_project_removal).to eq(false)
        end
      end
    end

    context 'when parent does not lock the attribute' do
      context 'and value is not nil' do
        before do
          group_settings.update!(delayed_project_removal: false)
        end

        it 'returns local setting when present' do
          subgroup_settings.update!(delayed_project_removal: true)

          expect(delayed_project_removal).to eq(true)
        end

        it 'returns the parent value when local value is nil' do
          subgroup_settings.update!(delayed_project_removal: nil)

          expect(delayed_project_removal).to eq(false)
        end

        it 'returns the correct dirty value' do
          subgroup_settings.delayed_project_removal = true

          expect(delayed_project_removal).to eq(true)
        end

        it 'does not return the application setting value when parent value is false' do
          stub_application_setting(delayed_project_removal: true)

          expect(delayed_project_removal).to eq(false)
        end
      end

      context 'and the value is nil' do
        before do
          group_settings.update!(delayed_project_removal: nil, lock_delayed_project_removal: false)
          subgroup_settings.update!(delayed_project_removal: nil)

          subgroup_settings.clear_memoization(:delayed_project_removal)
        end

        it 'cascades to the application settings value' do
          expect(delayed_project_removal).to eq(false)
        end
      end

      context 'when multiple ancestors set a value' do
        let(:third_level_subgroup) { create(:group, parent: subgroup) }

        before do
          group_settings.update!(delayed_project_removal: true)
          subgroup_settings.update!(delayed_project_removal: false)
        end

        it 'returns the closest ancestor value' do
          expect(third_level_subgroup.namespace_settings.delayed_project_removal).to eq(false)
        end
      end
    end

    context 'when parent locks the attribute' do
      before do
        subgroup_settings.update!(delayed_project_removal: true)
        group_settings.update!(lock_delayed_project_removal: true, delayed_project_removal: false)

        subgroup_settings.clear_memoization(:delayed_project_removal)
        subgroup_settings.clear_memoization(:delayed_project_removal_locked_ancestor)
      end

      it 'returns the parent value' do
        expect(delayed_project_removal).to eq(false)
      end

      it 'does not allow the local value to be saved' do
        subgroup_settings.delayed_project_removal = nil

        expect { subgroup_settings.save! }
          .to raise_error(ActiveRecord::RecordInvalid, /Delayed project removal cannot be changed because it is locked by an ancestor/)
      end
    end

    context 'when the application settings locks the attribute' do
      before do
        subgroup_settings.update!(delayed_project_removal: true)
        stub_application_setting(lock_delayed_project_removal: true, delayed_project_removal: true)
      end

      it 'returns the application setting value' do
        expect(delayed_project_removal).to eq(true)
      end

      it 'does not allow the local value to be saved' do
        subgroup_settings.delayed_project_removal = false

        expect { subgroup_settings.save! }
          .to raise_error(ActiveRecord::RecordInvalid, /Delayed project removal cannot be changed because it is locked by an ancestor/)
      end
    end
  end

  describe '#delayed_project_removal?' do
    before do
      subgroup_settings.update!(delayed_project_removal: true)
      group_settings.update!(lock_delayed_project_removal: true, delayed_project_removal: false)

      subgroup_settings.clear_memoization(:delayed_project_removal)
      subgroup_settings.clear_memoization(:delayed_project_removal_locked_ancestor)
    end

    it 'aliases the method when the attribute is a boolean' do
      expect(subgroup_settings.delayed_project_removal?).to eq(subgroup_settings.delayed_project_removal)
    end
  end

  describe '#delayed_project_removal=' do
    before do
      subgroup_settings.update!(delayed_project_removal: nil)
      group_settings.update!(delayed_project_removal: true)
    end

    it 'does not save the value locally when it matches the cascaded value' do
      subgroup_settings.update!(delayed_project_removal: true)

      expect(subgroup_settings.read_attribute(:delayed_project_removal)).to eq(nil)
    end
  end

  describe '#delayed_project_removal_locked?' do
    shared_examples 'not locked' do
      it 'is not locked by an ancestor' do
        expect(subgroup_settings.delayed_project_removal_locked_by_ancestor?).to eq(false)
      end

      it 'is not locked by application setting' do
        expect(subgroup_settings.delayed_project_removal_locked_by_application_setting?).to eq(false)
      end

      it 'does not return a locked namespace' do
        expect(subgroup_settings.delayed_project_removal_locked_ancestor).to be_nil
      end
    end

    context 'when attribute is locked by self' do
      before do
        subgroup_settings.update!(lock_delayed_project_removal: true)
      end

      it 'is not locked by default' do
        expect(subgroup_settings.delayed_project_removal_locked?).to eq(false)
      end

      it 'is locked when including self' do
        expect(subgroup_settings.delayed_project_removal_locked?(include_self: true)).to eq(true)
      end
    end

    context 'when parent does not lock the attribute' do
      it_behaves_like 'not locked'
    end

    context 'when parent locks the attribute' do
      before do
        group_settings.update!(lock_delayed_project_removal: true, delayed_project_removal: false)

        subgroup_settings.clear_memoization(:delayed_project_removal)
        subgroup_settings.clear_memoization(:delayed_project_removal_locked_ancestor)
      end

      it 'is locked by an ancestor' do
        expect(subgroup_settings.delayed_project_removal_locked_by_ancestor?).to eq(true)
      end

      it 'is not locked by application setting' do
        expect(subgroup_settings.delayed_project_removal_locked_by_application_setting?).to eq(false)
      end

      it 'returns a locked namespace settings object' do
        expect(subgroup_settings.delayed_project_removal_locked_ancestor.namespace_id).to eq(group_settings.namespace_id)
      end
    end

    context 'when not locked by application settings' do
      before do
        stub_application_setting(lock_delayed_project_removal: false)
      end

      it_behaves_like 'not locked'
    end

    context 'when locked by application settings' do
      before do
        stub_application_setting(lock_delayed_project_removal: true)
      end

      it 'is not locked by an ancestor' do
        expect(subgroup_settings.delayed_project_removal_locked_by_ancestor?).to eq(false)
      end

      it 'is locked by application setting' do
        expect(subgroup_settings.delayed_project_removal_locked_by_application_setting?).to eq(true)
      end

      it 'does not return a locked namespace' do
        expect(subgroup_settings.delayed_project_removal_locked_ancestor).to be_nil
      end
    end
  end

  describe '#lock_delayed_project_removal=' do
    context 'when parent locks the attribute' do
      before do
        group_settings.update!(lock_delayed_project_removal: true, delayed_project_removal: false)

        subgroup_settings.clear_memoization(:delayed_project_removal)
        subgroup_settings.clear_memoization(:delayed_project_removal_locked_ancestor)
      end

      it 'does not allow the attribute to be saved' do
        subgroup_settings.lock_delayed_project_removal = true

        expect { subgroup_settings.save! }
          .to raise_error(ActiveRecord::RecordInvalid, /Lock delayed project removal cannot be changed because it is locked by an ancestor/)
      end
    end

    context 'when parent does not lock the attribute' do
      before do
        group_settings.update!(lock_delayed_project_removal: false)

        subgroup_settings.lock_delayed_project_removal = true
      end

      it 'allows the lock to be set when the attribute is not nil' do
        subgroup_settings.delayed_project_removal = true

        expect(subgroup_settings.save).to eq(true)
      end

      it 'does not allow the lock to be saved when the attribute is nil' do
        subgroup_settings.delayed_project_removal = nil

        expect { subgroup_settings.save! }
          .to raise_error(ActiveRecord::RecordInvalid, /Delayed project removal cannot be nil when locking the attribute/)
      end

      it 'copies the cascaded value when locking the attribute if the local value is nil', :aggregate_failures do
        subgroup_settings.delayed_project_removal = nil
        subgroup_settings.lock_delayed_project_removal = true

        expect(subgroup_settings.read_attribute(:delayed_project_removal)).to eq(false)
      end
    end

    context 'when application settings locks the attribute' do
      before do
        stub_application_setting(lock_delayed_project_removal: true)
      end

      it 'does not allow the attribute to be saved' do
        subgroup_settings.lock_delayed_project_removal = true

        expect { subgroup_settings.save! }
          .to raise_error(ActiveRecord::RecordInvalid, /Lock delayed project removal cannot be changed because it is locked by an ancestor/)
      end
    end

    context 'when application_settings does not lock the attribute' do
      before do
        stub_application_setting(lock_delayed_project_removal: false)
      end

      it 'allows the attribute to be saved' do
        subgroup_settings.delayed_project_removal = true
        subgroup_settings.lock_delayed_project_removal = true

        expect(subgroup_settings.save).to eq(true)
      end
    end
  end

  describe 'after update callback' do
    before do
      subgroup_settings.update!(lock_delayed_project_removal: true, delayed_project_removal: false)
    end

    it 'clears descendant locks' do
      group_settings.update!(lock_delayed_project_removal: true, delayed_project_removal: true)

      expect(subgroup_settings.reload.lock_delayed_project_removal).to eq(false)
    end
  end
end
