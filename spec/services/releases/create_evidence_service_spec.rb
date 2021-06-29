# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Releases::CreateEvidenceService do
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
end
