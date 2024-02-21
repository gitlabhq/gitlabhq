# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'a cascading project setting boolean attribute' do
  |settings_attribute_name:, settings_association: :project_setting|
  let_it_be_with_reload(:parent_group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, group: parent_group) }
  let(:parent_group_settings) { parent_group.namespace_settings }
  let(:project_settings) { project.send(settings_association) }

  describe "##{settings_attribute_name}" do
    subject(:cascading_attribute) { project_settings.send(settings_attribute_name) }

    before do
      stub_application_setting(settings_attribute_name => false)
    end

    context 'when parent does not lock the attribute' do
      before do
        parent_group_settings.update!(settings_attribute_name => false)
      end

      it 'returns project setting' do
        project_settings.update!(settings_attribute_name => true)

        expect(cascading_attribute).to eq(true)
      end

      it 'returns the correct dirty value' do
        project_settings.send("#{settings_attribute_name}=", true)

        expect(cascading_attribute).to eq(true)
      end
    end

    context 'when parent locks the attribute' do
      before do
        project_settings.update!(settings_attribute_name => false)
        parent_group_settings.update!(
          "lock_#{settings_attribute_name}" => true,
          settings_attribute_name => false
        )
        project_settings.clear_memoization("#{settings_attribute_name}_locked_ancestor")
      end

      it 'returns the parent value' do
        expect(cascading_attribute).to eq(false)
      end

      it 'does not allow the local value to be saved' do
        project_settings.send("#{settings_attribute_name}=", true)

        expect { project_settings.save! }.to raise_error(
          ActiveRecord::RecordInvalid,
          /cannot be changed because it is locked by an ancestor/
        )
      end
    end

    context 'when the application settings locks the attribute' do
      before do
        project_settings.update!(settings_attribute_name => true)
        stub_application_setting("lock_#{settings_attribute_name}" => true, settings_attribute_name => true)
      end

      it 'returns the application setting value' do
        expect(cascading_attribute).to eq(true)
      end

      it 'does not allow the local value to be saved' do
        project_settings.send("#{settings_attribute_name}=", false)

        expect { project_settings.save! }
          .to raise_error(
            ActiveRecord::RecordInvalid,
            /cannot be changed because it is locked by an ancestor/
          )
      end
    end

    context 'when parent locked the attribute then the application settings locks it' do
      before do
        project_settings.update!(settings_attribute_name => true)
        parent_group_settings.update!("lock_#{settings_attribute_name}" => true, settings_attribute_name => false)
        stub_application_setting("lock_#{settings_attribute_name}" => true, settings_attribute_name => true)
      end

      it 'returns the application setting value' do
        expect(cascading_attribute).to eq(true)
      end
    end
  end

  describe "##{settings_attribute_name}_locked?" do
    shared_examples 'not locked' do
      it 'is not locked by an ancestor' do
        expect(project_settings.send("#{settings_attribute_name}_locked_by_ancestor?")).to eq(false)
      end

      it 'is not locked by application setting' do
        expect(project_settings.send("#{settings_attribute_name}_locked_by_application_setting?")).to eq(false)
      end

      it 'does not return a locked namespace' do
        expect(project_settings.send("#{settings_attribute_name}_locked_ancestor")).to be_nil
      end
    end

    context 'when parent does not lock the attribute' do
      it_behaves_like 'not locked'
    end

    context 'when parent locks the attribute' do
      before do
        parent_group_settings.update!("lock_#{settings_attribute_name}".to_sym => true,
          settings_attribute_name => false)
      end

      it 'is locked by an ancestor' do
        expect(project_settings.send("#{settings_attribute_name}_locked_by_ancestor?")).to eq(true)
      end

      it 'is not locked by application setting' do
        expect(project_settings.send("#{settings_attribute_name}_locked_by_application_setting?")).to eq(false)
      end

      it 'returns a locked namespace settings object' do
        expect(project_settings.send("#{settings_attribute_name}_locked_ancestor").namespace_id)
          .to eq(parent_group_settings.namespace_id)
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
        expect(project_settings.send("#{settings_attribute_name}_locked_by_ancestor?")).to eq(false)
      end

      it 'is locked by application setting' do
        expect(project_settings.send("#{settings_attribute_name}_locked_by_application_setting?")).to eq(true)
      end

      it 'does not return a locked namespace' do
        expect(project_settings.send("#{settings_attribute_name}_locked_ancestor")).to be_nil
      end
    end
  end
end
