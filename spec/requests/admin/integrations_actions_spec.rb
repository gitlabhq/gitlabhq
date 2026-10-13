# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::IntegrationsActions, feature_category: :integrations do
  let(:controller_class) do
    Class.new(ApplicationController) do
      include Admin::IntegrationsActions
    end
  end

  describe '#integrations_organization' do
    it 'must be defined by the including controller' do
      expect { controller_class.new.send(:integrations_organization) }.to raise_error(NotImplementedError)
    end
  end
end
