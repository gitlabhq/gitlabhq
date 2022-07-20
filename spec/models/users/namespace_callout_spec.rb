# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::NamespaceCallout do
  let_it_be(:user) { create_default(:user) }
  let_it_be(:namespace) { create_default(:namespace) }
  let_it_be(:callout) { create(:namespace_callout) }

  it_behaves_like 'having unique enum values'

  describe 'relationships' do
    it { is_expected.to belong_to(:namespace) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:namespace) }
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:feature_name) }

    specify do
      is_expected.to validate_uniqueness_of(:feature_name)
        .scoped_to(:user_id, :namespace_id)
        .ignoring_case_sensitivity
    end

    it { is_expected.to allow_value(:web_hook_disabled).for(:feature_name) }

    it 'rejects invalid feature names' do
      expect { callout.feature_name = :non_existent_feature }.to raise_error(ArgumentError)
    end
  end

  describe '#source_feature_name' do
    it 'provides string based off source and feature' do
      expect(callout.source_feature_name).to eq "#{callout.feature_name}_#{callout.namespace_id}"
    end
  end
end
