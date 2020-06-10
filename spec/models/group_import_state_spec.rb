# frozen_string_literal: true

require 'spec_helper'

describe GroupImportState do
  describe 'validations' do
    let_it_be(:group) { create(:group) }

    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:status) }

    it 'can be created without a jid' do
      import_state = build(:group_import_state, :created, group: group, jid: nil)

      expect(import_state).to be_valid
    end

    it 'cannot be started without a jid' do
      import_state = build(:group_import_state, :started, group: group, jid: nil)

      expect(import_state).not_to be_valid
      expect(import_state.errors[:jid]).to include "can't be blank"
    end

    it 'cannot be finished without a jid' do
      import_state = build(:group_import_state, :finished, group: group, jid: nil)

      expect(import_state).not_to be_valid
      expect(import_state.errors[:jid]).to include "can't be blank"
    end

    it 'can fail without a jid' do
      import_state = build(:group_import_state, :failed, group: group, jid: nil)

      expect(import_state).to be_valid
    end
  end
end
