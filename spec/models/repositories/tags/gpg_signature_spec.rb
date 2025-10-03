# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::Tags::GpgSignature, feature_category: :source_code_management do
  describe 'associations' do
    it { is_expected.to belong_to(:project).required(true) }
    it { is_expected.to belong_to(:gpg_key).required(false) }
    it { is_expected.to belong_to(:gpg_key_subkey).required(false) }
  end

  describe 'validation' do
    let_it_be(:gpg_key) { create(:gpg_key) }
    let_it_be(:project) { create(:project) }

    subject { create(:tag_gpg_signature, gpg_key: gpg_key, project: project) }

    it { is_expected.to validate_presence_of(:object_name) }
    it { is_expected.to validate_uniqueness_of(:object_name).scoped_to(:project_id).case_insensitive }
    it { is_expected.to validate_presence_of(:gpg_key_primary_keyid) }
  end
end
