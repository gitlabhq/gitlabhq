require 'rails_helper'
require_relative '../kubernetes_spec'

RSpec.describe Clusters::Kubernetes::HelmApp, type: :model do
  it_behaves_like 'a registered kubernetes app'

  it { is_expected.to belong_to(:kubernetes_service) }

  describe '#cluster' do
    it 'is an alias to #kubernetes_service' do
      expect(subject.method(:cluster).original_name).to eq(:kubernetes_service)
    end
  end
end
