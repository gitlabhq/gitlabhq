# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupImportState do
  describe 'validations' do
    let_it_be(:group) { create(:group) }

    it { is_expected.to belong_to(:user).required }
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

  describe '#in_progress?' do
    context "when the import is 'created'" do
      it "returns true" do
        group_import_state = build(:group_import_state, :created)

        expect(group_import_state.in_progress?).to eq true
      end
    end

    context "when the import is 'started'" do
      it "returns true" do
        group_import_state = build(:group_import_state, :started)

        expect(group_import_state.in_progress?).to eq true
      end
    end

    context "when the import is 'finished'" do
      it "returns false" do
        group_import_state = build(:group_import_state, :finished)

        expect(group_import_state.in_progress?).to eq false
      end
    end

    context "when the import is 'failed'" do
      it "returns false" do
        group_import_state = build(:group_import_state, :failed)

        expect(group_import_state.in_progress?).to eq false
      end
    end
  end

  context 'when import failed' do
    context 'when error message is present' do
      it 'truncates error message' do
        group_import_state = build(:group_import_state, :started)
        group_import_state.fail_op('e' * 300)

        expect(group_import_state.last_error.length).to eq(255)
      end
    end

    context 'when error message is missing' do
      it 'has no error message' do
        group_import_state = build(:group_import_state, :started)
        group_import_state.fail_op

        expect(group_import_state.last_error).to be_nil
      end
    end
  end
end
