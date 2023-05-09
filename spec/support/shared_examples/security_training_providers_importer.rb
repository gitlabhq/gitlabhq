# frozen_string_literal: true

RSpec.shared_examples 'security training providers importer' do
  let(:security_training_providers) do
    Class.new(ApplicationRecord) do
      self.table_name = 'security_training_providers'
    end
  end

  it 'upserts security training providers' do
    expect { 3.times { subject } }.to change { security_training_providers.count }.from(0).to(3)
    expect(security_training_providers.all.map(&:name)).to match_array(['Kontra', 'Secure Code Warrior', 'SecureFlag'])
  end
end
