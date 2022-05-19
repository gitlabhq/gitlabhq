# frozen_string_literal: true

RSpec.shared_context 'reconfigures connection stack' do |db_config_name|
  before do
    skip_if_multiple_databases_not_setup

    # Due to lib/gitlab/database/load_balancing/configuration.rb:92 requiring RequestStore
    # we cannot use stub_feature_flags(force_no_sharing_primary_model: true)
    Gitlab::Database.database_base_models.each do |_, model_class|
      allow(model_class.load_balancer.configuration).to receive(:use_dedicated_connection?).and_return(true)
    end

    ActiveRecord::Base.establish_connection(db_config_name.to_sym) # rubocop:disable Database/EstablishConnection

    expect(Gitlab::Database.db_config_name(ActiveRecord::Base.connection)) # rubocop:disable Database/MultipleDatabases
      .to eq(db_config_name)
  end

  around do |example|
    with_reestablished_active_record_base do
      example.run
    end
  end

  def validate_connections!
    model_connections = Gitlab::Database.database_base_models.to_h do |db_config_name, model_class|
      [model_class, Gitlab::Database.db_config_name(model_class.connection)]
    end

    expect(model_connections).to eq(Gitlab::Database.database_base_models.invert)
  end
end
