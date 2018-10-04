require 'spec_helper'

describe BlobEntity do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:blob) { project.commit('master').diffs.diff_files.first.blob }
  let(:request) { EntityRequest.new(project: project, ref: 'master') }

  let(:entity) do
    described_class.new(blob, request: request)
  end

  context 'as json' do
    subject { entity.as_json }

    it 'exposes needed attributes' do
      expect(subject).to include(:readable_text, :url)
    end
  end
end
