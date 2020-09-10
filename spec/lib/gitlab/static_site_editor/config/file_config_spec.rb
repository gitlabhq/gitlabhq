# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::StaticSiteEditor::Config::FileConfig do
  subject(:config) { described_class.new }

  describe '#data' do
    subject { config.data }

    it 'returns hardcoded data for now' do
      is_expected.to match(
        merge_requests_illustration_path: %r{illustrations/merge_requests}
      )
    end
  end
end
