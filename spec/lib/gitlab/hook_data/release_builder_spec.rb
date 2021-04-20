# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HookData::ReleaseBuilder do
  let_it_be(:project) { create(:project, :public, :repository) }

  let(:release) { create(:release, project: project) }
  let(:builder) { described_class.new(release) }

  describe '#build' do
    let(:data) { builder.build('create') }

    it 'includes safe attribute' do
      %w[
          id
          created_at
          description
          name
          released_at
          tag
      ].each do |key|
        expect(data).to include(key)
      end
    end

    it 'includes additional attrs' do
      expect(data[:object_kind]).to eq('release')
      expect(data[:project]).to eq(builder.release.project.hook_attrs.with_indifferent_access)
      expect(data[:action]).to eq('create')
      expect(data).to include(:assets)
      expect(data).to include(:commit)
    end

    context 'when the Release has an image in the description' do
      let(:release_with_description) do
        create(:release, project: project, description: 'test![Release_Image](/uploads/abc/Release_Image.png)')
      end

      let(:builder) { described_class.new(release_with_description) }

      it 'sets the image to use an absolute URL' do
        expected_path = "#{release_with_description.project.path_with_namespace}/uploads/abc/Release_Image.png"

        expect(data[:description])
          .to eq("test![Release_Image](#{Settings.gitlab.url}/#{expected_path})")
      end
    end
  end
end
