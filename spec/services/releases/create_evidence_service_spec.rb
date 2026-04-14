# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Releases::CreateEvidenceService, feature_category: :release_orchestration do
  let_it_be(:project) { create(:project) }

  let(:release) { create(:release, project: project) }
  let(:service) { described_class.new(release) }

  it 'creates evidence' do
    expect { service.execute }.to change { release.reload.evidences.count }.by(1)
  end

  it 'saves evidence summary' do
    service.execute
    evidence = Releases::Evidence.last

    expect(release.tag).not_to be_nil
    expect(evidence.summary["release"]["tag_name"]).to eq(release.tag)
  end

  it 'saves sha' do
    service.execute
    evidence = Releases::Evidence.last

    expect(evidence.summary_sha).not_to be_nil
  end

  context 'when the release has associated packages' do
    let_it_be(:release) { create(:release, project: project, tag: 'v1.0.0') }
    let_it_be(:package) { create(:generic_package, project: project, version: '1.0.0') }

    it 'includes packages in the evidence summary' do
      service.execute
      evidence = Releases::Evidence.last

      packages = evidence.summary["release"]["packages"]
      expect(packages).to contain_exactly(
        a_hash_including("name" => package.name, "version" => "1.0.0")
      )
    end
  end

  context 'when the release has no associated packages' do
    it 'includes an empty packages array in the evidence summary' do
      service.execute
      evidence = Releases::Evidence.last

      expect(evidence.summary["release"]["packages"]).to eq([])
    end
  end
end
