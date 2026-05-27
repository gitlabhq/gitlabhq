# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DesignManagement::Repository, feature_category: :design_management do
  let_it_be(:project) { create(:project) }
  let(:subject) { described_class.new({ project: project }) }

  describe 'associations' do
    it { is_expected.to belong_to(:project).inverse_of(:design_management_repository) }
    it { is_expected.to belong_to(:namespace) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_uniqueness_of(:project) }
  end

  describe '#full_path' do
    it "returns the project's full path" do
      expect(subject.full_path).to eq(project.full_path + Gitlab::GlRepository::DESIGN.path_suffix)
    end

    context 'when project is nil' do
      # This allows subject.id not to be nil for the error message assertion
      before do
        subject.save!
        subject.project_id = nil
      end

      it 'raises ActiveRecord::RecordNotFound' do
        expect { subject.full_path }.to raise_error(ActiveRecord::RecordNotFound,
          "Project not found for DesignManagement::Repository ##{subject.id}")
      end
    end
  end

  describe '#disk_path' do
    it "returns the project's disk path" do
      expect(subject.disk_path).to eq(project.disk_path + Gitlab::GlRepository::DESIGN.path_suffix)
    end

    context 'when project is nil' do
      # This allows subject.id not to be nil for the error message assertion
      before do
        subject.save!
        subject.project_id = nil
      end

      it 'raises ActiveRecord::RecordNotFound' do
        expect { subject.disk_path }.to raise_error(ActiveRecord::RecordNotFound,
          "Project not found for DesignManagement::Repository ##{subject.id}")
      end
    end
  end

  describe '#repository' do
    it 'returns a DesignManagement::GitRepository' do
      expect(subject.repository).to be_a(DesignManagement::GitRepository)
    end

    # Covers the Geo replicator regression path: the replicator calls
    # model_record.repository, which invokes full_path internally.
    # Without the nil guard, this raises NoMethodError instead of
    # ActiveRecord::RecordNotFound, escaping Geo's error handling.
    context 'when project is nil' do
      # This allows subject.id not to be nil for the error message assertion
      before do
        subject.save!
        subject.project_id = nil
      end

      it 'raises ActiveRecord::RecordNotFound' do
        expect { subject.repository }.to raise_error(ActiveRecord::RecordNotFound,
          "Project not found for DesignManagement::Repository ##{subject.id}")
      end
    end
  end
end
