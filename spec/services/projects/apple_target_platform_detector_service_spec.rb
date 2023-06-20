# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::AppleTargetPlatformDetectorService, feature_category: :groups_and_projects do
  let_it_be(:project) { build(:project) }

  subject { described_class.new(project).execute }

  context 'when project is not an xcode project' do
    before do
      allow(Gitlab::FileFinder).to receive(:new) { instance_double(Gitlab::FileFinder, find: []) }
    end

    it 'returns an empty array' do
      is_expected.to match_array []
    end
  end

  context 'when project is an xcode project' do
    using RSpec::Parameterized::TableSyntax

    let(:finder) { instance_double(Gitlab::FileFinder) }

    before do
      allow(Gitlab::FileFinder).to receive(:new) { finder }
    end

    def search_query(sdk, filename)
      "SDKROOT = #{sdk} filename:#{filename}"
    end

    context 'when setting string is found' do
      where(:sdk, :filename, :result) do
        'iphoneos'  | 'project.pbxproj' | [:ios]
        'iphoneos'  | '*.xcconfig'      | [:ios]
      end

      with_them do
        before do
          allow(finder).to receive(:find).with(anything) { [] }
          allow(finder).to receive(:find).with(search_query(sdk, filename)) { [instance_double(Gitlab::Search::FoundBlob)] }
        end

        it 'returns an array of unique detected targets' do
          is_expected.to match_array result
        end
      end
    end

    context 'when setting string is not found' do
      before do
        allow(finder).to receive(:find).with(anything) { [] }
      end

      it 'returns an empty array' do
        is_expected.to match_array []
      end
    end
  end
end
