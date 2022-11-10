# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::ExtensionHelpers do
  let(:model) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  before do
    allow(model).to receive(:puts)
  end

  describe '#create_extension' do
    subject { model.create_extension(extension) }

    let(:extension) { :btree_gist }

    it 'executes CREATE EXTENSION statement' do
      expect(model).to receive(:execute).with(/CREATE EXTENSION IF NOT EXISTS #{extension}/)

      subject
    end

    context 'without proper permissions' do
      before do
        allow(model).to receive(:execute)
          .with(/CREATE EXTENSION IF NOT EXISTS #{extension}/)
          .and_raise(ActiveRecord::StatementInvalid, 'InsufficientPrivilege: permission denied')
      end

      it 'raises an exception and prints an error message' do
        expect { subject }
          .to output(/user is not allowed/).to_stderr
          .and raise_error(ActiveRecord::StatementInvalid, /InsufficientPrivilege/)
      end
    end
  end

  describe '#drop_extension' do
    subject { model.drop_extension(extension) }

    let(:extension) { 'btree_gist' }

    it 'executes CREATE EXTENSION statement' do
      expect(model).to receive(:execute).with(/DROP EXTENSION IF EXISTS #{extension}/)

      subject
    end

    context 'without proper permissions' do
      before do
        allow(model).to receive(:execute)
          .with(/DROP EXTENSION IF EXISTS #{extension}/)
          .and_raise(ActiveRecord::StatementInvalid, 'InsufficientPrivilege: permission denied')
      end

      it 'raises an exception and prints an error message' do
        expect { subject }
          .to output(/user is not allowed/).to_stderr
          .and raise_error(ActiveRecord::StatementInvalid, /InsufficientPrivilege/)
      end
    end
  end
end
