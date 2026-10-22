# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::JobArtifactAccess, feature_category: :permissions do
  let_it_be(:project) { create(:project) }

  let(:access) { described_class.new(project: project, accessibility: 'private', file_type: 'junit') }

  describe '.for' do
    it 'reads the access attributes, taking the project from the job' do
      artifact = build(:ci_job_artifact, :junit, :private, job: build(:ci_build, project: project))

      expect(described_class.for(artifact))
        .to eq(described_class.new(project: project, accessibility: 'private', file_type: 'junit'))
    end
  end

  # Authz::JobArtifactAccessPolicy may only read these
  it 'has a fixed set of attributes' do
    expect(described_class.members).to eq(%i[project accessibility file_type])
  end

  describe '#initialize' do
    it 'normalizes symbols so the policy cannot miss a value' do
      access = described_class.new(project: project, accessibility: :none, file_type: :junit)

      expect(access).to have_attributes(accessibility: 'none', file_type: 'junit')
    end
  end

  describe '#id' do
    it 'is built from every attribute' do
      expect(access.id).to eq("#{project.id}:private:junit")
    end
  end
end
