# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::Permission, feature_category: :permissions do
  it_behaves_like 'loadable from yaml' do
    let(:definition_name) { :create_issue }
  end

  it_behaves_like 'yaml backed permission'

  context 'for ignored files' do
    let(:metadata_permissions) do
      described_class.all.keys.map(&:to_s).any? { |element| element.include?('metadata.yml') }
    end

    it 'does not include metadata files' do
      expect(metadata_permissions).to be false
    end
  end
end
