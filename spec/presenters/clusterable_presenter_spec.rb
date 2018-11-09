# frozen_string_literal: true

require 'spec_helper'

describe ClusterablePresenter do
  include Gitlab::Routing.url_helpers

  describe '.fabricate' do
    let(:project) { create(:project) }

    subject { described_class.fabricate(project) }

    it 'creates an object from a descendant presenter' do
      expect(subject).to be_kind_of(ProjectClusterablePresenter)
    end
  end
end
