require 'spec_helper'

describe Geo::RepositoryBackfillService, services: true do
  let(:project) { create(:project) }

  subject { Geo::RepositoryBackfillService.new(project) }

  describe '#execute' do
    pending { raise 'must be implemented' }
  end
end
