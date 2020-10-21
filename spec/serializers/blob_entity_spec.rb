# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BlobEntity do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:blob) { project.commit('master').diffs.diff_files.first.blob }
  let(:request) { EntityRequest.new(project: project, ref: 'master') }

  let(:entity) do
    described_class.new(blob, request: request)
  end

  context 'as json' do
    subject { entity.as_json }

    it 'contains needed attributes' do
      expect(subject).to include({
        id: blob.id,
        path: blob.path,
        name: blob.name,
        mode: "100644",
        readable_text: true,
        icon: "doc-text",
        url: "/#{project.full_path}/-/blob/master/bar/branch-test.txt"
      })
    end
  end
end
