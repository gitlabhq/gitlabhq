# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BaseService, feature_category: :importers do
  let(:user) { build_stubbed(:user) }
  let(:client) { double('Client') } # rubocop:disable RSpec/VerifiedDoubles -- external client duck-typed by each importer
  let(:service) { described_class.new(client, user, {}) }

  describe '#request_channel=', :request_store do
    it 'stashes the value in the request store so ProjectImportState#after_create can pick it up' do
      service.request_channel = :ui

      expect(Gitlab::Import::RequestChannel.stashed).to eq(:ui)
    end
  end

  describe '#success', :clean_gitlab_redis_shared_state do
    let_it_be(:project) { create(:project, :import_scheduled, import_type: 'github') }

    it 'returns a success response' do
      expect(service.send(:success, project)).to include(status: :success, project: project)
    end
  end
end
