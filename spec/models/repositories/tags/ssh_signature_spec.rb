# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::Tags::SshSignature, feature_category: :source_code_management do
  describe 'associations' do
    it { is_expected.to belong_to(:project).required(true) }
    it { is_expected.to belong_to(:key).required(false) }
  end

  describe 'validation' do
    let_it_be(:project) { create(:project) }

    subject { create(:tag_ssh_signature, project: project) }

    it { is_expected.to validate_presence_of(:object_name) }
    it { is_expected.to validate_uniqueness_of(:object_name).scoped_to(:project_id).case_insensitive }
  end

  it_behaves_like 'signature with type checking', :ssh
end
