# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SetAllowImmediateNamespacesDeletionToFalseOnSaasBis, :migration, feature_category: :groups_and_projects do
  let(:migration) { described_class.new }
  let(:application_setting) { table(:application_settings) }

  before do
    application_setting.create!(namespace_deletion_settings: { allow_immediate_namespaces_deletion: true })
  end

  describe '#up' do
    context 'when on GitLab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'updates namespace_deletion_settings.allow_immediate_namespaces_deletion to false' do
        migrate!

        expect(application_setting.first.namespace_deletion_settings)
          .to eq("allow_immediate_namespaces_deletion" => false)
      end

      context 'when no record exist' do
        before do
          application_setting.delete_all
        end

        it 'does not raise any error' do
          expect { migrate! }.not_to raise_error
        end
      end
    end

    context 'when on Dedicated' do
      before do
        application_setting.last.update!(gitlab_dedicated_instance: true)
      end

      it 'updates namespace_deletion_settings.allow_immediate_namespaces_deletion to false' do
        migrate!

        expect(application_setting.first.namespace_deletion_settings)
          .to eq("allow_immediate_namespaces_deletion" => false)
      end

      context 'when no record exist' do
        before do
          application_setting.delete_all
        end

        it 'does not raise any error' do
          expect { migrate! }.not_to raise_error
        end
      end
    end

    context 'when not on GitLab.com or Dedicated' do
      before do
        allow(Gitlab).to receive(:com?).and_return(false)
        application_setting.last.update!(gitlab_dedicated_instance: false)
      end

      it 'does not update namespace_deletion_settings.allow_immediate_namespaces_deletion' do
        migrate!

        expect(application_setting.first.namespace_deletion_settings)
          .to eq("allow_immediate_namespaces_deletion" => true)
      end

      context 'when no record exist' do
        before do
          application_setting.delete_all
        end

        it 'does not raise any error' do
          expect { migrate! }.not_to raise_error
        end
      end
    end
  end

  describe '#down' do
    before do
      migration.up
    end

    context 'when on GitLab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'updates namespace_deletion_settings.allow_immediate_namespaces_deletion to true' do
        migration.down

        expect(application_setting.first.namespace_deletion_settings)
          .to eq("allow_immediate_namespaces_deletion" => true)
      end

      context 'when no record exist' do
        before do
          application_setting.delete_all
        end

        it 'does not raise any error' do
          expect { migration.down }.not_to raise_error
        end
      end
    end

    context 'when on Dedicated' do
      before do
        application_setting.last.update!(gitlab_dedicated_instance: true)
      end

      it 'updates namespace_deletion_settings.allow_immediate_namespaces_deletion to true' do
        migration.down

        expect(application_setting.first.namespace_deletion_settings)
          .to eq("allow_immediate_namespaces_deletion" => true)
      end

      context 'when no record exist' do
        before do
          application_setting.delete_all
        end

        it 'does not raise any error' do
          expect { migration.down }.not_to raise_error
        end
      end
    end

    context 'when not on GitLab.com or Dedicated' do
      before do
        allow(Gitlab).to receive(:com?).and_return(false)
        application_setting.last.update!(gitlab_dedicated_instance: false)
      end

      it 'does not update namespace_deletion_settings.allow_immediate_namespaces_deletion' do
        migration.down

        expect(application_setting.first.namespace_deletion_settings)
          .to eq("allow_immediate_namespaces_deletion" => true)
      end

      context 'when no record exist' do
        before do
          application_setting.delete_all
        end

        it 'does not raise any error' do
          expect { migration.down }.not_to raise_error
        end
      end
    end
  end
end
