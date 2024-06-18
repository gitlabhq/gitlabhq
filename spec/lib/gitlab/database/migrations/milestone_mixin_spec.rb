# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::MilestoneMixin, feature_category: :database do
  let(:migration_no_mixin) do
    Class.new(Gitlab::Database::Migration[2.1]) do
      def change
        # no-op here to make rubocop happy
      end
    end
  end

  let(:migration_mixin) do
    Class.new(Gitlab::Database::Migration[2.2]) do
      @_defining_file = 'db/migrate/00000000000000_example.rb'
    end
  end

  let(:migration_mixin_version) do
    Class.new(Gitlab::Database::Migration[2.2]) do
      milestone '16.4'
      @_defining_file = 'db/migrate/00000000000000_example.rb'
    end
  end

  let(:migration_mixin_version_post) do
    Class.new(Gitlab::Database::Migration[2.2]) do
      milestone '16.4'
      @_defining_file = 'db/post_migrate/00000000000000_example.rb'
    end
  end

  context 'when the mixin is not included' do
    it 'does not raise an error' do
      expect { migration_no_mixin.new(4, 4) }.not_to raise_error
    end
  end

  context 'when the mixin is included' do
    context 'when a milestone is not specified' do
      it "raises MilestoneNotSetError" do
        expect { migration_mixin.new(4, 4) }.to raise_error(
          "#{described_class}::MilestoneNotSetError".constantize
        )
      end
    end

    context 'when a milestone is specified' do
      it "does not raise an error" do
        expect { migration_mixin_version.new(4, 4) }.not_to raise_error
      end
    end

    context 'when initialize arguments are not provided' do
      it "does not raise an error" do
        expect { migration_mixin_version.new }.not_to raise_error
      end
    end

    context "when it's a regular migration" do
      it 'is a regular migration' do
        expect(migration_mixin_version.new(4, 4).version.type).to eq(:regular)
      end
    end

    context "when it's a post-deployment migration" do
      it 'is a regular migration' do
        expect(migration_mixin_version_post.new(4, 4).version.type).to eq(:post)
      end
    end
  end
end
