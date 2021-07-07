# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WikiPages::CreateService do
  it_behaves_like 'WikiPages::CreateService#execute', :project

  describe '#execute' do
    let_it_be(:project) { create(:project) }

    subject(:service) { described_class.new(container: project) }

    context 'when wiki create fails due to git error' do
      let(:wiki_git_error) { 'Could not create wiki page' }

      it 'catches the thrown error and returns a ServiceResponse error' do
        allow_next_instance_of(WikiPage) do |instance|
          allow(instance).to receive(:create).and_raise(Gitlab::Git::CommandError.new(wiki_git_error))
        end

        result = service.execute
        expect(result).to be_error
        expect(result.message).to eq(wiki_git_error)
      end
    end
  end
end
