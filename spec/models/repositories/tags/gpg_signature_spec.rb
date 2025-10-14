# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::Tags::GpgSignature, feature_category: :source_code_management do
  let_it_be(:gpg_key) { create(:gpg_key) }

  describe 'associations' do
    it { is_expected.to belong_to(:project).required(true) }
    it { is_expected.to belong_to(:gpg_key).required(false) }
    it { is_expected.to belong_to(:gpg_key_subkey).required(false) }
  end

  describe 'validation' do
    let_it_be(:project) { create(:project) }

    subject { create(:tag_gpg_signature, gpg_key: gpg_key, project: project) }

    it { is_expected.to validate_presence_of(:object_name) }
    it { is_expected.to validate_uniqueness_of(:object_name).scoped_to(:project_id).case_insensitive }
    it { is_expected.to validate_presence_of(:gpg_key_primary_keyid) }
  end

  it_behaves_like 'signature with type checking', :gpg

  describe 'accessing gpg_key' do
    let(:tag_gpg_signature) { build(:tag_gpg_signature) }

    context 'when setting a GpgKey' do
      before do
        tag_gpg_signature.gpg_key = gpg_key
      end

      it 'returns the gpg key' do
        expect(tag_gpg_signature.gpg_key).to eq(gpg_key)
        expect(tag_gpg_signature.gpg_key_id).to eq(gpg_key.id)
        expect(tag_gpg_signature.gpg_key_subkey_id).to be_nil
      end

      context 'and setting nil' do
        it 'sets gpg_key_id to nil' do
          expect do
            tag_gpg_signature.gpg_key = nil
          end.to change { tag_gpg_signature.gpg_key_id }.from(gpg_key.id).to(nil)
        end
      end
    end

    context 'when setting GpgKeySubkey' do
      let(:gpg_key_subkey) { create(:gpg_key_subkey, gpg_key: gpg_key) }

      before do
        tag_gpg_signature.gpg_key = gpg_key_subkey
      end

      it 'returns the sub key' do
        expect(tag_gpg_signature.gpg_key).to eq(gpg_key_subkey)
        expect(tag_gpg_signature.gpg_key_id).to be_nil
        expect(tag_gpg_signature.gpg_key_subkey_id).to eq(gpg_key_subkey.id)
      end

      context 'and setting nil' do
        it 'sets gpg_key_subkey to nil' do
          expect do
            tag_gpg_signature.gpg_key = nil
          end.to change { tag_gpg_signature.gpg_key_subkey_id }.from(gpg_key_subkey.id).to(nil)
        end
      end
    end
  end
end
