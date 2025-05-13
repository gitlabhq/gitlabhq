# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::Tasks::Repositories, feature_category: :backup_restore do
  let(:progress) { StringIO.new }
  let(:options)  { Backup::Options.new }
  let(:server_side_callable) { StringIO.new }

  subject(:task) { described_class.new(progress:, options:, server_side_callable:) }

  describe '#human_name' do
    context 'when repositories_server_side_backup is not enabled' do
      it 'returns repositories' do
        expect(task.human_name).to eq('repositories')
      end
    end

    context 'when repositories_server_side_backup is enabled' do
      let(:options) { Backup::Options.new(repositories_server_side_backup: true) }

      it 'returns repositories with Gitaly server-side suffix' do
        expect(task.human_name).to eq('repositories (Gitaly server-side)')
      end
    end
  end
end
