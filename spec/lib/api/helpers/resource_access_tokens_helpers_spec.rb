# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../lib/api/helpers/resource_access_tokens_helpers'

RSpec.describe API::Helpers::ResourceAccessTokensHelpers, feature_category: :system_access do
  let(:helper) do
    Class.new.include(described_class).new
  end

  describe '#find_source' do
    it 'resolves a project through the project finder' do
      allow(helper).to receive(:find_project!).with(1).and_return(:a_project)

      expect(helper.find_source('project', 1)).to eq(:a_project)
    end

    it 'resolves a group through the group finder' do
      allow(helper).to receive(:find_group!).with(2).and_return(:a_group)

      expect(helper.find_source('group', 2)).to eq(:a_group)
    end

    it 'raises for a source type that is neither project nor group' do
      expect { helper.find_source('user', 1) }
        .to raise_error(ArgumentError, 'Unknown source_type: user')
    end
  end

  describe '#find_token' do
    let(:token) { double }
    let(:bots) { double }
    let(:finder) { double }
    let(:finder_class) { double }
    let(:resource) { double }

    before do
      allow(resource).to receive(:bots).and_return(bots)
      stub_const('PersonalAccessTokensFinder', finder_class)
    end

    it 'searches the bots of the resource for a non-impersonation token' do
      allow(finder_class).to receive(:new)
        .with({ user: bots, impersonation: false }).and_return(finder)
      allow(finder).to receive(:find_by_id).with(7).and_return(token)

      expect(helper.find_token(resource, 7)).to be(token)
    end
  end
end
