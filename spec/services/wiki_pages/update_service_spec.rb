# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WikiPages::UpdateService do
  it_behaves_like 'WikiPages::UpdateService#execute', :project

  describe '#execute' do
    let_it_be(:project) { create(:project) }

    let(:page) { create(:wiki_page, project: project) }

    subject(:service) { described_class.new(container: project) }

    context 'when wiki create fails due to git error' do
      let(:wiki_git_error) { 'Could not update wiki page' }

      it 'catches the thrown error and returns a ServiceResponse error' do
        allow_next_instance_of(WikiPage) do |instance|
          allow(instance).to receive(:update).and_raise(Gitlab::Git::CommandError.new(wiki_git_error))
        end

        result = service.execute(page)
        expect(result).to be_error
        expect(result.message).to eq(wiki_git_error)
      end
    end
  end
end
