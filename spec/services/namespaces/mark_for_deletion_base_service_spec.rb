# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::MarkForDeletionBaseService, feature_category: :groups_and_projects do
  let(:service) { described_class.new(nil, nil) }

  shared_examples 'raises NotImplementedError' do |method_name|
    it 'raises NotImplementedError' do
      expect { service.send(method_name) }.to raise_error(NotImplementedError)
    end
  end

  describe '#remove_permission' do
    it_behaves_like 'raises NotImplementedError', :remove_permission
  end

  describe '#notification_method' do
    it_behaves_like 'raises NotImplementedError', :notification_method
  end

  describe '#resource_name' do
    it_behaves_like 'raises NotImplementedError', :resource_name
  end
end
