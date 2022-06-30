# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportExport::RelationExport, type: :model do
  subject { create(:project_relation_export) }

  describe 'associations' do
    it { is_expected.to belong_to(:project_export_job) }
    it { is_expected.to have_one(:upload) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project_export_job) }
    it { is_expected.to validate_presence_of(:relation) }
    it { is_expected.to validate_uniqueness_of(:relation).scoped_to(:project_export_job_id) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_numericality_of(:status).only_integer }
    it { is_expected.to validate_length_of(:relation).is_at_most(255) }
    it { is_expected.to validate_length_of(:jid).is_at_most(255) }
    it { is_expected.to validate_length_of(:export_error).is_at_most(300) }
  end
end
