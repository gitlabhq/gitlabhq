# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PagesDomainRemovalCronWorker, feature_category: :pages do
  subject(:worker) { described_class.new }

  describe '#perform' do
    context 'when there is domain which should be removed' do
      let!(:domain_for_removal) { create(:pages_domain, :should_be_removed) }

      it 'removes domain' do
        expect { worker.perform }.to change { PagesDomain.count }.by(-1)
        expect(PagesDomain.exists?).to eq(false)
      end
    end

    context 'where there is a domain which scheduled for removal in the future' do
      let!(:domain_for_removal) { create(:pages_domain, :scheduled_for_removal) }

      it 'does not remove pages domain' do
        expect { worker.perform }.not_to change { PagesDomain.count }
        expect(PagesDomain.find_by(domain: domain_for_removal.domain)).to be_present
      end
    end
  end
end
