# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeletePagesDomainWithReservedDomains, feature_category: :pages do
  describe 'migrates' do
    context 'when a reserved domain is provided' do
      it 'delete the domain' do
        table(:pages_domains).create!(domain: 'gmail.com', verification_code: 'gmail')
        expect { migrate! }.to change { PagesDomain.count }.by(-1)
      end
    end

    context 'when a reserved domain is provided with non standard case' do
      it 'delete the domain' do
        table(:pages_domains).create!(domain: 'AOl.com', verification_code: 'aol')
        expect { migrate! }.to change { PagesDomain.count }.by(-1)
      end
    end

    context 'when a non reserved domain is provided' do
      it 'does not delete the domain' do
        table(:pages_domains).create!(domain: 'example.com', verification_code: 'example')
        expect { migrate! }.not_to change { PagesDomain.count }
        expect(table(:pages_domains).find_by(domain: 'example.com')).not_to be_nil
      end
    end
  end
end
