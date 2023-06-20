# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::ConvertFeatureCategoryToGroupLabel, feature_category: :database do
  describe '#execute' do
    subject(:group_label) { described_class.new(feature_category).execute }

    let_it_be(:stages_fixture) do
      { stages: { manage: { groups: { database: { categories: ['database'] } } } } }
    end

    before do
      stub_request(:get, 'https://gitlab.com/gitlab-com/www-gitlab-com/-/raw/master/data/stages.yml')
        .to_return(status: 200, body: stages_fixture.to_json, headers: {})
    end

    context 'when the group label exists' do
      let(:feature_category) { 'database' }

      it 'returns a group label' do
        expect(group_label).to eql 'group::database'
      end
    end

    context 'when the group label does not exist' do
      let(:feature_category) { 'non_existing_feature_category_test' }

      it 'returns nil' do
        expect(group_label).to be nil
      end
    end
  end
end
