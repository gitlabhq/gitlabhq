# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DesignManagement::Repository, feature_category: :design_management do
  let_it_be(:project) { create(:project) }
  let(:subject) { described_class.new({ project: project }) }

  describe 'associations' do
    it { is_expected.to belong_to(:project).inverse_of(:design_management_repository) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_uniqueness_of(:project) }
  end

  it "returns the project's full path" do
    expect(subject.full_path).to eq(project.full_path + Gitlab::GlRepository::DESIGN.path_suffix)
  end

  it "returns the project's disk path" do
    expect(subject.disk_path).to eq(project.disk_path + Gitlab::GlRepository::DESIGN.path_suffix)
  end
end
