# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::StaticSiteEditor::Config::FileConfig do
  subject(:config) { described_class.new }

  describe '#data' do
    subject { config.data }

    it 'returns hardcoded data for now' do
      is_expected.to match(static_site_generator: 'middleman')
    end
  end
end
