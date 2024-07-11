# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::NamespaceImportUser, type: :model, feature_category: :importers do
  let(:namespace_import_user) { create(:namespace_import_user) }

  describe 'associations' do
    it { is_expected.to belong_to(:import_user).class_name('User') }
    it { is_expected.to belong_to(:namespace) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:namespace_id) }
    it { is_expected.to validate_presence_of(:user_id) }
  end

  describe 'cascade deletion' do
    context 'when user is removed' do
      it 'removes namespace import user' do
        namespace_import_user.import_user.destroy!

        expect { namespace_import_user.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when namespace is removed' do
      it 'removes namespace import user' do
        namespace_import_user.namespace.destroy!

        expect { namespace_import_user.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
