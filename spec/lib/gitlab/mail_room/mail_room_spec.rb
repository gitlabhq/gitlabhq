# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::MailRoom, feature_category: :build do
  let(:default_port) { 143 }
  let(:log_path) { Rails.root.join('log', 'mail_room_json.log').to_s }

  let(:fake_redis_queues) do
    double(
      url: "localhost",
      db: 99,
      sentinels: [{ host: 'localhost', port: 1234 }],
      sentinels?: true
    )
  end

  let(:yml_config) do
    {
      enabled: true,
      host: 'mail.example.com',
      address: 'address@example.com',
      user: 'user@example.com',
      password: 'password',
      port: default_port,
      ssl: false,
      start_tls: false,
      mailbox: 'inbox',
      idle_timeout: 60,
      log_path: log_path,
      expunge_deleted: false
    }
  end

  let(:custom_config) { {} }
  let(:incoming_email_config) { yml_config.merge(custom_config) }
  let(:service_desk_email_config) { yml_config.merge(custom_config) }

  let(:configs) do
    {
      incoming_email: incoming_email_config,
      service_desk_email: service_desk_email_config
    }
  end

  before do
    allow(Gitlab::Redis::Queues).to receive(:new).and_return(fake_redis_queues)
    allow(described_class).to receive(:load_yaml).and_return(configs)
    described_class.instance_variable_set(:@enabled_configs, nil)
  end

  after do
    described_class.instance_variable_set(:@enabled_configs, nil)
  end

  describe '#enabled_configs' do
    let(:first_value) { described_class.enabled_configs.each_value.first }

    context 'when both email and address is set' do
      it 'returns email configs' do
        expect(described_class.enabled_configs.size).to eq(2)
      end
    end

    context 'when the yml file cannot be found' do
      before do
        allow(described_class).to receive(:config_file).and_return('not_existing_file')
      end

      it 'returns an empty list' do
        expect(described_class.enabled_configs).to be_empty
      end
    end

    context 'when email is disabled' do
      let(:custom_config) { { enabled: false } }

      it 'returns an empty list' do
        expect(described_class.enabled_configs).to be_empty
      end
    end

    context 'when email is enabled but address is not set' do
      let(:custom_config) { { enabled: true, address: '' } }

      it 'returns an empty list' do
        expect(described_class.enabled_configs).to be_empty
      end
    end

    context 'when a config value is missing from the yml file' do
      let(:yml_config) { {} }
      let(:custom_config) { { enabled: true, address: 'address@example.com' } }

      it 'overwrites missing values with the default' do
        expect(first_value[:port]).to eq(Gitlab::MailRoom::DEFAULT_CONFIG[:port])
      end
    end

    context 'when only incoming_email config is present' do
      let(:configs) { { incoming_email: incoming_email_config } }

      it 'returns only encoming_email' do
        expect(described_class.enabled_configs.size).to eq(1)
        expect(first_value[:worker]).to eq('EmailReceiverWorker')
      end
    end

    describe 'setting up redis settings' do
      it 'sets delivery method to Sidekiq by default' do
        config = first_value
        expect(config).to include(
          delivery_method: 'sidekiq'
        )
      end

      it 'sets redis config' do
        config = first_value
        expect(config).to include(
          redis_url: 'localhost',
          redis_db: 99,
          sentinels: [{ host: 'localhost', port: 1234 }]
        )
      end
    end

    describe 'setting up the log path' do
      context 'if the log path is a relative path' do
        let(:custom_config) { { log_path: 'tiny_log.log' } }

        it 'expands the log path to an absolute value' do
          new_path = Pathname.new(first_value[:log_path])
          expect(new_path.absolute?).to be_truthy
        end
      end

      context 'if the log path is absolute path' do
        let(:custom_config) { { log_path: '/dev/null' } }

        it 'leaves the path as-is' do
          expect(first_value[:log_path]).to eq '/dev/null'
        end
      end
    end
  end

  describe '#enabled_mailbox_types' do
    context 'when all mailbox types are enabled' do
      it 'returns the mailbox types' do
        expect(described_class.enabled_mailbox_types).to match(%w[incoming_email service_desk_email])
      end
    end

    context 'when an mailbox_types is disabled' do
      let(:incoming_email_config) { yml_config.merge(enabled: false) }

      it 'returns the mailbox types' do
        expect(described_class.enabled_mailbox_types).to match(%w[service_desk_email])
      end
    end

    context 'when email is disabled' do
      let(:custom_config) { { enabled: false } }

      it 'returns an empty array' do
        expect(described_class.enabled_mailbox_types).to be_empty
      end
    end
  end

  describe '#worker_for' do
    context 'matched mailbox types' do
      it 'returns the constantized worker class' do
        expect(described_class.worker_for('incoming_email')).to eql(EmailReceiverWorker)
        expect(described_class.worker_for('service_desk_email')).to eql(ServiceDeskEmailReceiverWorker)
      end
    end

    context 'non-existing mailbox_type' do
      it 'returns nil' do
        expect(described_class.worker_for('another_mailbox_type')).to be(nil)
      end
    end
  end

  describe 'config/mail_room.yml' do
    let(:mail_room_template) { ERB.new(File.read(Rails.root.join("./config/mail_room.yml"))).result }
    let(:mail_room_yml) { YAML.safe_load(mail_room_template, permitted_classes: [Symbol]) }

    shared_examples 'renders mail-specific config file correctly' do
      it 'renders mail room config file correctly' do
        expect(mail_room_yml[:mailboxes]).to be_an(Array)
        expect(mail_room_yml[:mailboxes].length).to eq(2)

        expect(mail_room_yml[:mailboxes]).to all(
          match(
            a_hash_including(
              host: 'mail.example.com',
              port: default_port,
              ssl: false,
              start_tls: false,
              email: 'user@example.com',
              password: 'password',
              idle_timeout: 60,
              logger: {
                log_path: log_path
              },
              name: 'inbox',

              delete_after_delivery: true,
              expunge_deleted: false
            )
          )
        )
      end
    end

    shared_examples 'renders arbitration options correctly' do
      it 'renders arbitration options correctly' do
        expect(mail_room_yml[:mailboxes]).to be_an(Array)
        expect(mail_room_yml[:mailboxes].length).to eq(2)
        expect(mail_room_yml[:mailboxes]).to all(
          match(
            a_hash_including(
              arbitration_method: "redis",
              arbitration_options: {
                redis_url: "localhost",
                namespace: "mail_room:gitlab",
                sentinels: [{ host: "localhost", port: 1234 }]
              }
            )
          )
        )
      end
    end

    shared_examples 'renders the sidekiq delivery method and options correctly' do
      it 'renders the sidekiq delivery method and options correctly' do
        expect(mail_room_yml[:mailboxes]).to be_an(Array)
        expect(mail_room_yml[:mailboxes].length).to eq(2)

        expect(mail_room_yml[:mailboxes][0]).to match(
          a_hash_including(
            delivery_method: 'sidekiq',
            delivery_options: {
              redis_url: "localhost",
              redis_db: 99,
              queue: "default",
              worker: "EmailReceiverWorker",
              sentinels: [{ host: "localhost", port: 1234 }]
            }
          )
        )
        expect(mail_room_yml[:mailboxes][1]).to match(
          a_hash_including(
            delivery_method: 'sidekiq',
            delivery_options: {
              redis_url: "localhost",
              redis_db: 99,
              queue: "default",
              worker: "ServiceDeskEmailReceiverWorker",
              sentinels: [{ host: "localhost", port: 1234 }]
            }
          )
        )
      end
    end

    context 'when delivery_method is implicit' do
      it_behaves_like 'renders mail-specific config file correctly'
      it_behaves_like 'renders arbitration options correctly'
      it_behaves_like 'renders the sidekiq delivery method and options correctly'
    end

    context 'when delivery_method is explicitly sidekiq' do
      let(:custom_config) { { delivery_method: 'sidekiq' } }

      it_behaves_like 'renders mail-specific config file correctly'
      it_behaves_like 'renders arbitration options correctly'
      it_behaves_like 'renders the sidekiq delivery method and options correctly'
    end

    context 'when delivery_method is webhook (internally postback in mail_room)' do
      let(:custom_config) do
        {
          delivery_method: 'webhook',
          gitlab_url: 'http://gitlab.example',
          secret_file: '/path/to/secret/file'
        }
      end

      it_behaves_like 'renders mail-specific config file correctly'
      it_behaves_like 'renders arbitration options correctly'

      it 'renders the webhook (postback) delivery method and options correctly' do
        expect(mail_room_yml[:mailboxes]).to be_an(Array)
        expect(mail_room_yml[:mailboxes].length).to eq(2)

        expect(mail_room_yml[:mailboxes][0]).to match(
          a_hash_including(
            delivery_method: 'postback',
            delivery_options: {
              delivery_url: "http://gitlab.example/api/v4/internal/mail_room/incoming_email",
              content_type: "text/plain",
              jwt_auth_header: Gitlab::MailRoom::INTERNAL_API_REQUEST_HEADER,
              jwt_issuer: Gitlab::MailRoom::INTERNAL_API_REQUEST_JWT_ISSUER,
              jwt_algorithm: 'HS256',
              jwt_secret_path: '/path/to/secret/file'
            }
          )
        )

        expect(mail_room_yml[:mailboxes][1]).to match(
          a_hash_including(
            delivery_method: 'postback',
            delivery_options: {
              delivery_url: "http://gitlab.example/api/v4/internal/mail_room/service_desk_email",
              content_type: "text/plain",
              jwt_auth_header: Gitlab::MailRoom::INTERNAL_API_REQUEST_HEADER,
              jwt_issuer: Gitlab::MailRoom::INTERNAL_API_REQUEST_JWT_ISSUER,
              jwt_algorithm: 'HS256',
              jwt_secret_path: '/path/to/secret/file'
            }
          )
        )
      end
    end
  end

  describe 'mailroom encrypted configuration' do
    context "when parsing secrets.yml" do
      let(:application_secrets_file) { Rails.root.join('spec/fixtures/mail_room/secrets.yml.erb').to_s }
      let(:encrypted_settings_key_base) { '0123456789abcdef' * 8 }

      before do
        allow(described_class).to receive(:application_secrets_file).and_return(application_secrets_file)
        stub_env('KEY', 'an environment variable value')
        described_class.instance_variable_set(:@application_secrets, nil)
      end

      after do
        described_class.instance_variable_set(:@application_secrets, nil)
      end

      it 'reads in the secrets.yml file as erb and merges shared and test environments' do
        application_secrets = described_class.send(:application_secrets)

        expect(application_secrets).to match(a_hash_including(
          a_shared_key: 'this key is shared',
          an_overriden_shared_key: 'the merge overwrote this key',
          an_environment_specific_key: 'test environment value',
          erb_env_key: 'an environment variable value',
          encrypted_settings_key_base: encrypted_settings_key_base
        ))

        expect(application_secrets[:an_unread_key]).to be_nil
      end
    end

    context "when parsing gitlab.yml" do
      let(:plain_configs) { configs }
      let(:shared_path_config) do
        { shared: { path: '/this/is/my/shared_path' } }.merge(configs)
      end

      let(:encrypted_settings_config) do
        {
          shared: { path: '/this/is/my/shared_path' },
          encrypted_settings: { path: '/this/is/my_custom_encrypted_path' }
        }.merge(configs)
      end

      let(:encrypted_file_config) do
        configs.deep_merge({
          incoming_email: { encrypted_secret_file: '/custom_incoming_secret.yaml.enc' },
          service_desk_email: { encrypted_secret_file: '/custom_service_desk_secret.yaml.enc' }
        })
      end

      it 'returns default encrypted_secret_file path' do
        allow(described_class).to receive(:load_yaml).and_return(plain_configs)

        expect(described_class.send(:encrypted_secret_file, :incoming_email))
          .to end_with('shared/encrypted_settings/incoming_email.yaml.enc')

        expect(described_class.send(:encrypted_secret_file, :service_desk_email))
          .to end_with('shared/encrypted_settings/service_desk_email.yaml.enc')
      end

      it 'returns encrypted_secret_file relative to custom shared path' do
        allow(described_class).to receive(:load_yaml).and_return(shared_path_config)

        expect(described_class.send(:encrypted_secret_file, :incoming_email))
          .to eq('/this/is/my/shared_path/encrypted_settings/incoming_email.yaml.enc')

        expect(described_class.send(:encrypted_secret_file, :service_desk_email))
          .to eq('/this/is/my/shared_path/encrypted_settings/service_desk_email.yaml.enc')
      end

      it 'returns custom encrypted_secret_file' do
        allow(described_class).to receive(:load_yaml).and_return(encrypted_file_config)

        expect(described_class.send(:encrypted_secret_file, :incoming_email))
          .to eq('/custom_incoming_secret.yaml.enc')

        expect(described_class.send(:encrypted_secret_file, :service_desk_email))
          .to eq('/custom_service_desk_secret.yaml.enc')
      end
    end

    context 'when using encrypted secrets' do
      let(:mail_room_template) { ERB.new(File.read(Rails.root.join("./config/mail_room.yml"))).result }
      let(:mail_room_yml) { YAML.safe_load(mail_room_template, permitted_classes: [Symbol]) }
      let(:application_secrets) { { encrypted_settings_key_base: '0123456789abcdef' * 8 } } # gitleaks:allow
      let(:configs) do
        {
          encrypted_settings: { path: 'spec/fixtures/mail_room/encrypted_secrets' }
        }.merge({
          incoming_email: incoming_email_config,
          service_desk_email: service_desk_email_config
        })
      end

      before do
        allow(described_class).to receive(:application_secrets).and_return(application_secrets)
      end

      it 'renders the encrypted secrets into the configuration correctly' do
        expect(mail_room_yml[:mailboxes]).to be_an(Array)
        expect(mail_room_yml[:mailboxes].length).to eq(2)

        expect(mail_room_yml[:mailboxes][0]).to match(
          a_hash_including(
            password: 'abc123',
            email: 'incoming-test-account@gitlab.com'
          )
        )

        expect(mail_room_yml[:mailboxes][1]).to match(
          a_hash_including(
            password: '123abc',
            email: 'service-desk-test-account@gitlab.example.com'
          )
        )
      end
    end
  end
end
