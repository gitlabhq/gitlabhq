# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'a cascading namespace setting boolean attribute' do
  |settings_attribute_name:, settings_association: :namespace_settings|
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:subgroup) { create(:group, parent: group) }
  let(:group_settings) { group.send(settings_association) }
  let(:subgroup_settings) { subgroup.send(settings_association) }

  describe "##{settings_attribute_name}" do
    subject(:cascading_attribute) { subgroup_settings.send(settings_attribute_name) }

    before do
      stub_application_setting(settings_attribute_name => false)
    end

    context 'when there is no parent' do
      context 'and the value is not nil' do
        before do
          group_settings.update!(settings_attribute_name => true)
        end

        it 'returns the local value' do
          expect(group_settings.send(settings_attribute_name)).to eq(true)
        end
      end

      context 'and the value is nil' do
        before do
          group_settings.update!(settings_attribute_name => nil)
        end

        it 'returns the application settings value' do
          expect(group_settings.send(settings_attribute_name)).to eq(false)
        end
      end
    end

    context 'when parent does not lock the attribute' do
      context 'and value is not nil' do
        before do
          group_settings.update!(settings_attribute_name => false)
        end

        it 'returns local setting when present' do
          subgroup_settings.update!(settings_attribute_name => true)

          expect(cascading_attribute).to eq(true)
        end

        it 'returns the parent value when local value is nil' do
          subgroup_settings.update!(settings_attribute_name => nil)

          expect(cascading_attribute).to eq(false)
        end

        it 'returns the correct dirty value' do
          subgroup_settings.send("#{settings_attribute_name}=", true)

          expect(cascading_attribute).to eq(true)
        end

        it 'does not return the application setting value when parent value is false' do
          stub_application_setting(settings_attribute_name => true)

          expect(cascading_attribute).to eq(false)
        end
      end

      context 'and the value is nil' do
        before do
          group_settings.update!(settings_attribute_name => nil, "lock_#{settings_attribute_name}".to_sym => false)
          subgroup_settings.update!(settings_attribute_name => nil)

          subgroup_settings.clear_memoization(settings_attribute_name)
        end

        it 'cascades to the application settings value' do
          expect(cascading_attribute).to eq(false)
        end
      end

      context 'when multiple ancestors set a value' do
        let(:third_level_subgroup) { create(:group, parent: subgroup) }

        before do
          group_settings.update!(settings_attribute_name => true)
          subgroup_settings.update!(settings_attribute_name => false)
        end

        it 'returns the closest ancestor value' do
          expect(third_level_subgroup.send(settings_association).send(settings_attribute_name)).to eq(false)
        end
      end
    end

    context 'when parent locks the attribute' do
      before do
        subgroup_settings.update!(settings_attribute_name => true)
        group_settings.update!("lock_#{settings_attribute_name}" => true, settings_attribute_name => false)

        subgroup_settings.clear_memoization(settings_attribute_name)
        subgroup_settings.clear_memoization("#{settings_attribute_name}_locked_ancestor")
      end

      it 'returns the parent value' do
        expect(cascading_attribute).to eq(false)
      end

      it 'does not allow the local value to be saved' do
        subgroup_settings.send("#{settings_attribute_name}=", nil)

        expect { subgroup_settings.save! }.to raise_error(
          ActiveRecord::RecordInvalid,
          /cannot be changed because it is locked by an ancestor/
        )
      end
    end

    context 'when the application settings locks the attribute' do
      before do
        subgroup_settings.update!(settings_attribute_name => true)
        stub_application_setting("lock_#{settings_attribute_name}" => true, settings_attribute_name => true)
      end

      it 'returns the application setting value' do
        expect(cascading_attribute).to eq(true)
      end

      it 'does not allow the local value to be saved' do
        subgroup_settings.send("#{settings_attribute_name}=", false)

        expect { subgroup_settings.save! }
          .to raise_error(
            ActiveRecord::RecordInvalid,
            /cannot be changed because it is locked by an ancestor/
          )
      end
    end

    context 'when parent locked the attribute then the application settings locks it' do
      before do
        subgroup_settings.update!(settings_attribute_name => true)
        group_settings.update!("lock_#{settings_attribute_name}" => true, settings_attribute_name => false)
        stub_application_setting("lock_#{settings_attribute_name}" => true, settings_attribute_name => true)

        subgroup_settings.clear_memoization(settings_attribute_name)
        subgroup_settings.clear_memoization("#{settings_attribute_name}_locked_ancestor")
      end

      it 'returns the application setting value' do
        expect(cascading_attribute).to eq(true)
      end
    end
  end

  describe "##{settings_attribute_name}?" do
    before do
      subgroup_settings.update!(settings_attribute_name => true)
      group_settings.update!("lock_#{settings_attribute_name}" => true, settings_attribute_name => false)

      subgroup_settings.clear_memoization(settings_attribute_name)
      subgroup_settings.clear_memoization("#{settings_attribute_name}_locked_ancestor")
    end

    it 'aliases the method when the attribute is a boolean' do
      expect(subgroup_settings.send("#{settings_attribute_name}?"))
        .to eq(subgroup_settings.send(settings_attribute_name))
    end
  end

  describe "##{settings_attribute_name}=" do
    using RSpec::Parameterized::TableSyntax

    where(:parent_value, :current_subgroup_value, :new_subgroup_value, :expected_subgroup_value_after_update) do
      true  | nil   |  true   | nil
      true  | nil   | "true"  | nil
      true  | false |  true   | true
      true  | false | "true"  | true
      true  | true  |  false  | false
      true  | true  | "false" | false
      false | nil   |  false  | nil
      false | nil   |  true   | true
      false | true  |  false  | false
      false | false |  true   | true
    end

    with_them do
      before do
        subgroup_settings.update!(settings_attribute_name => current_subgroup_value)
        group_settings.update!(settings_attribute_name => parent_value)
      end

      it 'validates starting values from before block', :aggregate_failures do
        expect(group_settings.reload.read_attribute(settings_attribute_name)).to eq(parent_value)
        expect(subgroup_settings.reload.read_attribute(settings_attribute_name)).to eq(current_subgroup_value)
      end

      it 'does not save the value locally when it matches cascaded value', :aggregate_failures do
        subgroup_settings.send("#{settings_attribute_name}=", new_subgroup_value)

        # Verify dirty value
        expect(subgroup_settings.read_attribute(settings_attribute_name)).to eq(expected_subgroup_value_after_update)

        subgroup_settings.save!

        # Verify persisted value
        expect(subgroup_settings.reload.read_attribute(settings_attribute_name))
          .to eq(expected_subgroup_value_after_update)
      end

      context 'when mass assigned' do
        before do
          subgroup_settings.attributes =
            { settings_attribute_name => new_subgroup_value, "lock_#{settings_attribute_name}" => false }
        end

        it 'does not save the value locally when it matches cascaded value', :aggregate_failures do
          subgroup_settings.save!

          # Verify persisted value
          expect(subgroup_settings.reload.read_attribute(settings_attribute_name))
            .to eq(expected_subgroup_value_after_update)
        end
      end
    end
  end

  describe "##{settings_attribute_name}_locked?" do
    shared_examples 'not locked' do
      it 'is not locked by an ancestor' do
        expect(subgroup_settings.send("#{settings_attribute_name}_locked_by_ancestor?")).to eq(false)
      end

      it 'is not locked by application setting' do
        expect(subgroup_settings.send("#{settings_attribute_name}_locked_by_application_setting?")).to eq(false)
      end

      it 'does not return a locked namespace' do
        expect(subgroup_settings.send("#{settings_attribute_name}_locked_ancestor")).to be_nil
      end
    end

    context 'when attribute is locked by self' do
      before do
        subgroup_settings.update!("lock_#{settings_attribute_name}" => true)
      end

      it 'is not locked by default' do
        expect(subgroup_settings.send("#{settings_attribute_name}_locked?")).to eq(false)
      end

      it 'is locked when including self' do
        expect(subgroup_settings.send("#{settings_attribute_name}_locked?", include_self: true)).to eq(true)
      end
    end

    context 'when parent does not lock the attribute' do
      it_behaves_like 'not locked'
    end

    context 'when parent locks the attribute' do
      before do
        group_settings.update!("lock_#{settings_attribute_name}".to_sym => true, settings_attribute_name => false)

        subgroup_settings.clear_memoization(settings_attribute_name)
        subgroup_settings.clear_memoization("#{settings_attribute_name}_locked_ancestor")
      end

      it 'is locked by an ancestor' do
        expect(subgroup_settings.send("#{settings_attribute_name}_locked_by_ancestor?")).to eq(true)
      end

      it 'is not locked by application setting' do
        expect(subgroup_settings.send("#{settings_attribute_name}_locked_by_application_setting?")).to eq(false)
      end

      it 'returns a locked namespace settings object' do
        expect(subgroup_settings.send("#{settings_attribute_name}_locked_ancestor").namespace_id)
          .to eq(group_settings.namespace_id)
      end
    end

    context 'when not locked by application settings' do
      before do
        stub_application_setting("lock_#{settings_attribute_name}" => false)
      end

      it_behaves_like 'not locked'
    end

    context 'when locked by application settings' do
      before do
        stub_application_setting("lock_#{settings_attribute_name}" => true)
      end

      it 'is not locked by an ancestor' do
        expect(subgroup_settings.send("#{settings_attribute_name}_locked_by_ancestor?")).to eq(false)
      end

      it 'is locked by application setting' do
        expect(subgroup_settings.send("#{settings_attribute_name}_locked_by_application_setting?")).to eq(true)
      end

      it 'does not return a locked namespace' do
        expect(subgroup_settings.send("#{settings_attribute_name}_locked_ancestor")).to be_nil
      end
    end
  end

  describe "#lock_#{settings_attribute_name}=" do
    context 'when parent locks the attribute' do
      before do
        group_settings.update!("lock_#{settings_attribute_name}".to_sym => true, settings_attribute_name => false)

        subgroup_settings.clear_memoization(settings_attribute_name)
        subgroup_settings.clear_memoization("#{settings_attribute_name}_locked_ancestor")
      end

      it 'does not allow the attribute to be saved' do
        subgroup_settings.send("lock_#{settings_attribute_name}=", true)

        expect { subgroup_settings.save! }.to raise_error(
          ActiveRecord::RecordInvalid,
          /cannot be changed because it is locked by an ancestor/
        )
      end
    end

    context 'when parent does not lock the attribute' do
      before do
        group_settings.update!("lock_#{settings_attribute_name}" => false, settings_attribute_name => false)

        subgroup_settings.send("lock_#{settings_attribute_name}=", true)
      end

      it 'allows the lock to be set when the attribute is not nil' do
        subgroup_settings.send("#{settings_attribute_name}=", true)

        expect(subgroup_settings.save).to eq(true)
      end

      it 'does not allow the lock to be saved when the attribute is nil' do
        subgroup_settings.send("#{settings_attribute_name}=", nil)

        expect { subgroup_settings.save! }.to raise_error(
          ActiveRecord::RecordInvalid,
          /cannot be nil when locking the attribute/
        )
      end

      it 'copies the cascaded value when locking the attribute if the local value is nil', :aggregate_failures do
        subgroup_settings.send("#{settings_attribute_name}=", nil)
        subgroup_settings.send("lock_#{settings_attribute_name}=", true)

        expect(subgroup_settings.read_attribute(settings_attribute_name)).to eq(false)
      end
    end

    context 'when application settings locks the attribute' do
      before do
        stub_application_setting("lock_#{settings_attribute_name}".to_sym => true)
      end

      it 'does not allow the attribute to be saved' do
        subgroup_settings.send("lock_#{settings_attribute_name}=", true)

        expect { subgroup_settings.save! }.to raise_error(
          ActiveRecord::RecordInvalid,
          /cannot be changed because it is locked by an ancestor/
        )
      end
    end

    context 'when application_settings does not lock the attribute' do
      before do
        stub_application_setting("lock_#{settings_attribute_name}".to_sym => false)
      end

      it 'allows the attribute to be saved' do
        subgroup_settings.send("#{settings_attribute_name}=", true)
        subgroup_settings.send("lock_#{settings_attribute_name}=", true)

        expect(subgroup_settings.save).to eq(true)
      end
    end
  end

  describe 'after update callback' do
    before do
      group_settings.update!("lock_#{settings_attribute_name}" => false, settings_attribute_name => false)
      subgroup_settings.update!("lock_#{settings_attribute_name}" => true, settings_attribute_name => false)
    end

    it 'clears descendant locks' do
      group_settings.update!("lock_#{settings_attribute_name}" => true, settings_attribute_name => true)

      expect(subgroup_settings.reload.send("lock_#{settings_attribute_name}")).to eq(false)
    end
  end
end
