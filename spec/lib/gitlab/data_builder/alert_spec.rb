# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DataBuilder::Alert do
  let_it_be(:project) { create(:project) }
  let_it_be(:alert) { create(:alert_management_alert, project: project) }

  describe '.build' do
    let_it_be(:data) { described_class.build(alert) }

    it { expect(data).to be_a(Hash) }
    it { expect(data[:object_kind]).to eq('alert') }

    it 'contains the correct object attributes', :aggregate_failures do
      object_attributes = data[:object_attributes]

      expect(object_attributes[:title]).to eq(alert.title)
      expect(object_attributes[:url]).to eq(Gitlab::Routing.url_helpers.details_project_alert_management_url(project, alert.iid))
      expect(object_attributes[:severity]).to eq(alert.severity)
      expect(object_attributes[:events]).to eq(alert.events)
      expect(object_attributes[:status]).to eq(alert.status_name)
      expect(object_attributes[:started_at]).to eq(alert.started_at)
    end
  end
end
