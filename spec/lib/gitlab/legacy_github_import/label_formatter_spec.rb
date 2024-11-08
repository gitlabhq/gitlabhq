# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LegacyGithubImport::LabelFormatter do
  let_it_be(:project) { create(:project, :with_import_url, :import_user_mapping_enabled) }

  let(:raw) { { name: 'improvements', color: 'e6e6e6' } }

  subject(:label) { described_class.new(project, raw) }

  describe '#attributes' do
    it 'returns formatted attributes' do
      expect(label.attributes).to eq({
        project: project,
        title: 'improvements',
        color: '#e6e6e6'
      })
    end
  end

  describe '#contributing_user_formatters' do
    it { expect(label.contributing_user_formatters).to eq({}) }

    it 'includes all user reference columns in #attributes' do
      expect(label.contributing_user_formatters.keys).to match_array(
        label.attributes.keys & Gitlab::ImportExport::Base::RelationFactory::USER_REFERENCES.map(&:to_sym)
      )
    end
  end

  describe '#create!', :aggregate_failures, :clean_gitlab_redis_shared_state do
    let(:store) { project.placeholder_reference_store }

    it 'creates a new label when label does not exist' do
      expect { label.create! }.to change(Label, :count).by(1)
    end

    it 'does not create a new label when label exists' do
      Labels::CreateService.new(name: raw[:name]).execute(project: project)

      expect { label.create! }.not_to change(Label, :count)
    end

    it 'does not push any placeholder references because it does not reference a user' do
      label_user_references = label.attributes.keys & Gitlab::ImportExport::Base::RelationFactory::USER_REFERENCES
      label.create!

      expect(store.empty?).to be(true)
      expect(label_user_references).to be_empty
    end
  end
end
