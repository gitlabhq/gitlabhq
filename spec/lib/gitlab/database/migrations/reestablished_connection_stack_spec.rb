# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::ReestablishedConnectionStack do
  let(:base_class) { ActiveRecord::Migration }

  let(:model) do
    base_class.new
      .extend(described_class)
  end

  describe '#with_restored_connection_stack' do
    Gitlab::Database.database_base_models_with_gitlab_shared.each do |db_config_name, _|
      context db_config_name do
        it_behaves_like "reconfigures connection stack", db_config_name do
          it 'does restore connection hierarchy' do
            model.with_restored_connection_stack do
              validate_connections_stack!
            end
          end

          primary_db_config = ActiveRecord::Base.configurations.primary?(db_config_name)

          it 'does reconfigure connection handler', unless: primary_db_config do
            original_handler = ActiveRecord::Base.connection_handler
            new_handler = nil

            model.with_restored_connection_stack do
              new_handler = ActiveRecord::Base.connection_handler

              # establish connection
              ApplicationRecord.connection.select_one("SELECT 1 FROM projects LIMIT 1")
              Ci::ApplicationRecord.connection.select_one("SELECT 1 FROM p_ci_builds LIMIT 1")
            end

            expect(new_handler).not_to eq(original_handler), "is reconnected"
            expect(new_handler).not_to be_active_connections
            expect(ActiveRecord::Base.connection_handler).to eq(original_handler), "is restored"
          end

          it 'does keep original connection handler', if: primary_db_config do
            original_handler = ActiveRecord::Base.connection_handler
            new_handler = nil

            model.with_restored_connection_stack do
              new_handler = ActiveRecord::Base.connection_handler
            end

            expect(new_handler).to eq(original_handler)
            expect(ActiveRecord::Base.connection_handler).to eq(original_handler)
          end
        end
      end
    end
  end
end
