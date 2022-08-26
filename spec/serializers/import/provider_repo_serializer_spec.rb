# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::ProviderRepoSerializer do
  using RSpec::Parameterized::TableSyntax

  describe '#represent' do
    where(:provider, :class_name) do
      :github           | 'Import::GithubishProviderRepoEntity'
      :gitea            | 'Import::GithubishProviderRepoEntity'
      :bitbucket        | 'Import::BitbucketProviderRepoEntity'
      :bitbucket_server | 'Import::BitbucketServerProviderRepoEntity'
      :fogbugz          | 'Import::FogbugzProviderRepoEntity'
    end

    with_them do
      it 'uses correct entity class' do
        opts = { provider: provider }
        expect(class_name.constantize).to receive(:represent)
        described_class.new.represent({}, opts)
      end
    end

    it 'raises an error if invalid provider supplied' do
      expect { described_class.new.represent({}, { provider: :invalid }) }.to raise_error { NotImplementedError }
    end
  end
end
