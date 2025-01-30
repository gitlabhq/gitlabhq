# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Key, :mailer do
  it_behaves_like 'having unique enum values'

  describe "Associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:todos).dependent(:destroy) }
  end

  describe "Validation" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_most(255) }

    it { is_expected.to validate_presence_of(:key) }
    it { is_expected.to validate_length_of(:key).is_at_most(5000) }
    it { is_expected.to allow_value(attributes_for(:rsa_key_2048)[:key]).for(:key) }
    it { is_expected.to allow_value(attributes_for(:rsa_key_4096)[:key]).for(:key) }
    it { is_expected.to allow_value(attributes_for(:rsa_key_5120)[:key]).for(:key) }
    it { is_expected.to allow_value(attributes_for(:rsa_key_8192)[:key]).for(:key) }
    it { is_expected.to allow_value(attributes_for(:dsa_key_2048)[:key]).for(:key) }
    it { is_expected.to allow_value(attributes_for(:ecdsa_key_256)[:key]).for(:key) }
    it { is_expected.to allow_value(attributes_for(:ed25519_key_256)[:key]).for(:key) }
    it { is_expected.to allow_value(attributes_for(:ecdsa_sk_key_256)[:key]).for(:key) }
    it { is_expected.to allow_value(attributes_for(:ed25519_sk_key_256)[:key]).for(:key) }
    it { is_expected.not_to allow_value('foo-bar').for(:key) }

    context 'key format' do
      let(:key) { build(:key) }

      it 'does not allow the key that begins with an algorithm name that is unsupported' do
        key.key = 'unsupported-ssh-rsa key'

        key.valid?

        expect(key.errors.of_kind?(:key, :invalid)).to eq(true)
      end

      Gitlab::SSHPublicKey.supported_algorithms.each do |supported_algorithm|
        it "allows the key that begins with supported algorithm name '#{supported_algorithm}'" do
          key.key = "#{supported_algorithm} key"

          key.valid?

          expect(key.errors.of_kind?(:key, :invalid)).to eq(false)
        end
      end
    end

    describe 'validation of banned keys' do
      let(:key) { build(:key) }

      where(:key_content) do
        [
          'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEAwRIdDlHaIqZXND/l1vFT7ue3rc/DvXh2y' \
          'x5EFtuxGQRHVxGMazDhV4vj5ANGXDQwUYI0iZh6aOVrDy8I/y9/y+YDGCvsnqrDbuPDjW' \
          '26s2bBXWgUPiC93T3TA6L2KOxhVcl7mljEOIYACRHPpJNYVGhinCxDUH9LxMrdNXgP5Ok= mateidu@localhost',

          'ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIBnZQ+6nhlPX/JnX5i5hXpljJ89bSnnrsSs51' \
          'hSPuoJGmoKowBddISK7s10AIpO0xAWGcr8PUr2FOjEBbDHqlRxoXF0Ocms9xv3ql9EYUQ5' \
          '+U+M6BymWhNTFPOs6gFHUl8Bw3t6c+SRKBpfRFB0yzBj9d093gSdfTAFoz+yLo4vRw==',

          'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEAvIhC5skTzxyHif/7iy3yhxuK6/OB13hjPq' \
          'rskogkYFrcW8OK4VJT+5+Fx7wd4sQCnVn8rNqahw/x6sfcOMDI/Xvn4yKU4t8TnYf2MpUV' \
          'r4ndz39L5Ds1n7Si1m2suUNxWbKv58I8+NMhlt2ITraSuTU0NGymWOc8+LNi+MHXdLk= SCCP Superuser',

          'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr' \
          '+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6' \
          'IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5' \
          'y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0j' \
          'MZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98' \
          'OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key',

          'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEAwRIdDlHaIqZXND/l1vFT7ue3rc/DvXh2yx' \
          '5EFtuxGQRHVxGMazDhV4vj5ANGXDQwUYI0iZh6aOVrDy8I/y9/y+YDGCvsnqrDbuPDjW26' \
          's2bBXWgUPiC93T3TA6L2KOxhVcl7mljEOIYACRHPpJNYVGhinCxDUH9LxMrdNXgP5Ok= mateidu@localhost',

          'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEAn8LoId2N5i28cNKuEWWea3yt0I/LdT/NRO' \
          'rF44WZewtxch+DIwteQhM1qL6EKUSqz3Q2geX1crpOsNnyh67xy5lNo086u/QewOCSRAUG' \
          'rQCXqFQ4JU8ny/qugWALQHjbIaPHj/3zMK09r4cpTSeAU7CW5nQyTKGmh7v9CAfWfcs= adam@localhost.localdomain',

          'ssh-dss AAAAB3NzaC1kc3MAAACBAJTDsX+8olPZeyr58g9XE0L8PKT5030NZBPlE7np4h' \
          'Bqx36HoWarWq1Csn8M57dWN9StKbs03k2ggY6sYJK5AW2EWar70um3pYjKQHiZq7mITmit' \
          'sozFN/K7wu2e2iKRgquUwH5SuYoOJ29n7uhaILXiKZP4/H/dDudqPRSY6tJPAAAAFQDtuW' \
          'H90mDbU2L/Ms2lfl/cja/wHwAAAIAMBwSHZt2ysOHCFe1WLUvdwVDHUqk3QHTskuuAnMlw' \
          'MtSvCaUxSatdHahsMZ9VCHjoQUx6j+TcgRLDbMlRLnwUlb6wpniehLBFk+qakGcREqks5N' \
          'xYzFTJXwROzP72jPvVgQyOZHWq81gCild/ljL7hmrduCqYwxDIz4o7U92UKQAAAIBmhSl9' \
          'CVPgVMv1xO8DAHVhM1huIIK8mNFrzMJz+JXzBx81ms1kWSeQOC/nraaXFTBlqiQsvB8tzr' \
          '4xZdbaI/QzVLKNAF5C8BJ4ScNlTIx1aZJwyMil8Nzb+0YAsw5Ja+bEZZvEVlAYnd10qRWr' \
          'PeEY1txLMmX3wDa+JvJL7fmuBg==',

          'ssh-dss AAAAB3NzaC1kc3MAAACBAMq5EcIFdfCjJakyQnP/BBp9oc6mpaZVguf0Znp5C4' \
          '0twiG1lASQJZlM1qOB/hkBWYeBCHUkcOLEnVXSZzB62L+W/LGKodqnsiQPRr57AA6jPc6m' \
          'NBnejHai8cSdAl9n/0s2IQjdcrxM8CPq2uEyfm0J3AV6Lrbbxr5NgE5xxM+DAAAAFQCmFk' \
          '/M7Rx2jexsJ9COpHkHwUjcNQAAAIAdg18oByp/tjjDKhWhmmv+HbVIROkRqSxBvuEZEmcW' \
          'lg38mLIT1bydfpSou/V4rI5ctxwCfJ1rRr66pw6GwCrz4fXmyVlhrj7TrktyQ9+zRXhynF' \
          '4wdNPWErhNHb8tGlSOFiOBcUTlouX3V/ka6Dkd6ZQrZLQFaH+gjfyTZZ82HQAAAIEArsJg' \
          'p7RLPOsCeLqoia/eljseBFVDazO5Q0ysUotTw9wgXGGVWREwm8wNggFNb9eCiBAAUfVZVf' \
          'hVAtFT0pBf/eIVLPXyaMw3prBt7LqeBrbagODc3WAAdMTPIdYYcOKgv+YvTXa51zG64v6p' \
          'QOfS8WXgKCzDl44puXfYeDk5lVQ=',

          'ssh-dss AAAAB3NzaC1kc3MAAACBAKwKBw7D4OA1H/uD4htdh04TBIHdbSjeXUSnWJsce8' \
          'C0tvoB01Yarjv9TFj+tfeDYVWtUK1DA1JkyqSuoAtDANJzF4I6Isyd0KPrW3dHFTcg6Xlz' \
          '8d3KEaHokY93NOmB/xWEkhme8b7Q0U2iZie2pgWbTLXV0FA+lhskTtPHW3+VAAAAFQDRya' \
          'yUlVZKXEweF3bUe03zt9e8VQAAAIAEPK1k3Y6ErAbIl96dnUCnZjuWQ7xXy062pf63QuRW' \
          'I6LYSscm3f1pEknWUNFr/erQ02pkfi2eP9uHl1TI1ql+UmJX3g3frfssLNZwWXAW0m8PbY' \
          '3HZSs+f5hevM3ua32pnKDmbQ2WpvKNyycKHi81hSI14xMcdblJolhN5iY8/wAAAIAjEe5+' \
          '0m/TlBtVkqQbUit+s/g+eB+PFQ+raaQdL1uztW3etntXAPH1MjxsAC/vthWYSTYXORkDFM' \
          'hrO5ssE2rfg9io0NDyTIZt+VRQMGdi++dH8ptU+ldl2ZejLFdTJFwFgcfXz+iQ1mx6h9TP' \
          'X1crE1KoMAVOj3yKVfKpLB1EkA== root@lbslave',

          'ssh-dss AAAAB3NzaC1kc3MAAACBAN3AITryJMQyOKZjAky+mQ/8pOHIlu4q8pzmR0qotK' \
          'aLm2yye5a0PY2rOaQRAzi7EPheBXbqTb8a8TrHhGXI5P7GUHaJho5HhEnw+5TwAvP72L7L' \
          'cPwxMxj/rLcR/jV+uLMsVeJVWjwJcUv83yzPXoVjK0hrIm+RLLeuTM+gTylHAAAAFQD5gB' \
          'dXsXAiTz1atzMg3xDFF1zlowAAAIAlLy6TCMlOBM0IcPsvP/9bEjDj0M8YZazdqt4amO2I' \
          'aNUPYt9/sIsLOQfxIj8myDK1TOp8NyRJep7V5aICG4f3Q+XktlmLzdWn3sjvbWuIAXe1op' \
          'jG2T69YhxfHZr8Wn7P4tpCgyqM4uHmUKrfnBzQQ9vkUUWsZoUXM2Z7vUXVfQAAAIAU6eNl' \
          'phQWDwx0KOBiiYhF9BM6kDbQlyw8333rAG3G4CcjI2G8eYGtpBNliaD185UjCEsjPiudhG' \
          'il/j4Zt/+VY3aGOLoi8kqXBBc8ZAML9bbkXpyhQhMgwiywx3ciFmvSn2UAin8yurStYPQx' \
          'tXauZN5PYbdwCHPS7ApIStdpMA== wood@endec1',

          'ssh-dss AAAAB3NzaC1kc3MAAACBAISAE3CAX4hsxTw0dRc0gx8nQ41r3Vkj9OmG6LGeKW' \
          'Rmpy7C6vaExuupjxid76fd4aS56lCUEEoRlJ3zE93qoK9acI6EGqGQFLuDZ0fqMyRSX+il' \
          'f+1HDo/TRyuraggxp9Hj9LMpZVbpFATMm0+d9Xs7eLmaJjuMsowNlOf8NFdHAAAAFQCwdv' \
          'qOAkR6QhuiAapQ/9iVuR0UAQAAAIBpLMo4dhSeWkChfv659WLPftxRrX/HR8YMD/jqa3R4' \
          'PsVM2g6dQ1191nHugtdV7uaMeOqOJ/QRWeYM+UYwT0Zgx2LqvgVSjNDfdjk+ZRY8x3SmEx' \
          'Fi62mKFoTGSOCXfcAfuanjaoF+sepnaiLUd+SoJShGYHoqR2QWiysTRqknlwAAAIBLEgYm' \
          'r9XCSqjENFDVQPFELYKT7Zs9J87PjPS1AP0qF1OoRGZ5mefK6X/6VivPAUWmmmev/BuAs8' \
          'M1HtfGeGGzMzDIiU/WZQ3bScLB1Ykrcjk7TOFD6xrnk/inYAp5l29hjidoAONcXoHmUAMY' \
          'OKqn63Q2AsDpExVcmfj99/BlpQ=='
        ]
      end

      with_them do
        it 'does not allow banned keys' do
          key.key = key_content

          expect(key).to be_invalid
          expect(key.errors[:key]).to include(
            _('cannot be used because it belongs to a compromised private key. Stop using this key and generate a new one.'))
        end
      end
    end
  end

  describe "Methods" do
    let(:user) { create(:user) }

    it { is_expected.to respond_to :projects }
    it { is_expected.to respond_to :publishable_key }

    describe "#publishable_keys" do
      it 'replaces SSH key comment with simple identifier of username + hostname' do
        expect(build(:key, user: user).publishable_key).to include("#{user.name} (#{Gitlab.config.gitlab.host})")
      end
    end

    describe "#update_last_used_at" do
      it 'updates the last used timestamp' do
        key = build(:key)
        service = double(:service)

        expect(Keys::LastUsedService).to receive(:new)
          .with(key)
          .and_return(service)

        expect(service).to receive(:execute_async)

        key.update_last_used_at
      end
    end

    describe '#readable_by?' do
      subject { key.readable_by?(user) }

      context 'when key belongs to user' do
        let(:key) { build(:key, user: user) }

        it { is_expected.to eq true }
      end

      context 'when key does not belong to user' do
        let(:key) { build(:key, user_id: non_existing_record_id) }

        it { is_expected.to eq false }
      end
    end

    describe '#to_reference' do
      # This method is only needed to support the Key target for the *Haml* to-do app.
      # TODO: Remove this test and method when deleting the old Haml to-do app's code.
      let(:key) { build(:key, user: user) }

      it 'returns the SSH key\'s fingerprint' do
        expect(key.to_reference).to eq key.fingerprint
      end
    end
  end

  describe 'scopes' do
    describe '.for_user' do
      let(:user_1) { create(:user) }
      let(:key_of_user_1) { create(:personal_key, user: user_1) }

      before do
        create_list(:personal_key, 2, user: create(:user))
      end

      it 'returns keys of the specified user only' do
        expect(described_class.for_user(user_1)).to contain_exactly(key_of_user_1)
      end
    end

    describe 'created at scopes', :time_freeze do
      let!(:created_last_month_key) { create(:key, :expired, created_at: 1.month.ago) }
      let!(:created_next_month_key) { create(:key, created_at: 1.month.from_now) }
      let!(:created_two_months_key) { create(:key, created_at: 2.months.from_now) }

      describe '.created_before' do
        it 'finds keys that expire before or on date' do
          expect(described_class.created_before(1.month.ago)).to contain_exactly(created_last_month_key)
        end
      end

      describe '.created_after' do
        it 'finds keys that created after or on date' do
          expect(described_class.created_after(1.month.from_now.beginning_of_hour))
            .to contain_exactly(created_next_month_key, created_two_months_key)
        end
      end
    end

    describe '.order_last_used_at_desc' do
      it 'sorts by last_used_at descending, with null values at last' do
        key_1 = create(:personal_key, last_used_at: 7.days.ago)
        key_2 = create(:personal_key, last_used_at: nil)
        key_3 = create(:personal_key, last_used_at: 2.days.ago)

        expect(described_class.order_last_used_at_desc)
          .to eq([key_3, key_1, key_2])
      end
    end

    context 'expiration scopes', :time_freeze do
      let_it_be(:user) { create(:user) }
      let_it_be(:expired_today_not_notified) { create(:key, :expired_today, user: user) }
      let_it_be(:expired_today_already_notified) { create(:key, :expired_today, user: user, expiry_notification_delivered_at: Time.current) }
      let_it_be(:expired_yesterday) { create(:key, :expired, user: user) }
      let_it_be(:expiring_soon_unotified) { create(:key, expires_at: 3.days.from_now, user: user) }
      let_it_be(:expiring_soon_notified) { create(:key, expires_at: 4.days.from_now, user: user, before_expiry_notification_delivered_at: Time.current) }
      let_it_be(:future_expiry) { create(:key, expires_at: 1.month.from_now, user: user) }

      describe '.expired_today_and_not_notified' do
        it 'returns keys that expire today and have not been notified' do
          expect(described_class.expired_today_and_not_notified).to contain_exactly(expired_today_not_notified)
        end
      end

      describe '.expiring_soon_and_not_notified' do
        it 'returns keys that will expire soon' do
          expect(described_class.expiring_soon_and_not_notified).to contain_exactly(expiring_soon_unotified)
        end
      end

      describe '.expires_before' do
        it 'finds keys that expire before or on date' do
          expect(described_class.expires_before(1.day.from_now))
            .to contain_exactly(expired_today_not_notified, expired_today_already_notified, expired_yesterday)
        end
      end

      describe '.expires_after' do
        it 'finds keys that expires after or on date' do
          expect(described_class.expires_after(3.days.from_now.beginning_of_hour))
            .to contain_exactly(expiring_soon_unotified, expiring_soon_notified, future_expiry)
        end
      end
    end

    context 'usage type scopes' do
      let_it_be(:auth_key) { create(:key, usage_type: :auth) }
      let_it_be(:auth_and_signing_key) { create(:key, usage_type: :auth_and_signing) }
      let_it_be(:signing_key) { create(:key, usage_type: :signing) }

      it 'auth scope returns auth and auth_and_signing keys' do
        expect(described_class.auth).to match_array([auth_key, auth_and_signing_key])
      end

      it 'signing scope returns signing and auth_and_signing keys' do
        expect(described_class.signing).to match_array([signing_key, auth_and_signing_key])
      end
    end

    describe '.regular_keys' do
      let_it_be(:personal_key) { create(:personal_key) }
      let_it_be(:key) { create(:key) }
      let_it_be(:deploy_key) { create(:deploy_key) }

      it 'does not return keys of type DeployKey' do
        expect(described_class.all).to match_array([personal_key, key, deploy_key])
        expect(described_class.regular_keys).to match_array([personal_key, key])
      end
    end
  end

  describe 'modules' do
    it { expect(described_class.included_modules).to include(Todoable) }
  end

  context 'validation of uniqueness (based on fingerprint uniqueness)' do
    let(:user) { create(:user) }

    it 'accepts the key once' do
      expect(build(:rsa_key_4096, user: user)).to be_valid
    end

    it 'does not accept the exact same key twice' do
      first_key = create(:rsa_key_4096, user: user)

      expect(build(:key, user: user, key: first_key.key)).not_to be_valid
    end

    it 'does not accept a duplicate key with a different comment' do
      first_key = create(:rsa_key_4096, user: user)
      duplicate = build(:key, user: user, key: first_key.key)
      duplicate.key << ' extra comment'

      expect(duplicate).not_to be_valid
    end
  end

  describe '#ensure_sha256_fingerprint!' do
    let_it_be_with_reload(:user_key) { create(:personal_key) }

    context 'with a valid SHA256 fingerprint' do
      it 'does nothing' do
        expect(user_key).not_to receive(:generate_fingerprint)

        user_key.ensure_sha256_fingerprint!
      end
    end

    context 'with a missing SHA256 fingerprint' do
      before do
        user_key.update_column(:fingerprint_sha256, nil)
        user_key.ensure_sha256_fingerprint!
      end

      it 'fingerprints are present' do
        expect(user_key.reload.fingerprint_sha256).to be_present
      end
    end

    context 'with an invalid public key' do
      before do
        user_key.update_column(:key, 'a')
      end

      it 'does not throw an exception' do
        expect { user_key.ensure_sha256_fingerprint! }.not_to raise_error
      end
    end
  end

  context 'fingerprint generation' do
    it 'generates both md5 and sha256 fingerprints' do
      key = build(:rsa_key_4096)

      expect(key).to be_valid
      expect(key.fingerprint).to be_kind_of(String)
      expect(key.fingerprint_sha256).to be_kind_of(String)
    end

    context 'with FIPS mode', :fips_mode do
      it 'generates only sha256 fingerprint' do
        key = build(:rsa_key_4096)

        expect(key).to be_valid
        expect(key.fingerprint).to be_nil
        expect(key.fingerprint_sha256).to be_kind_of(String)
      end
    end
  end

  context "validate it is a fingerprintable key" do
    it "accepts the fingerprintable key" do
      expect(build(:key)).to be_valid
    end

    it 'rejects the unfingerprintable key (not a key)' do
      expect(build(:key, key: 'ssh-rsa an-invalid-key==')).not_to be_valid
    end

    where(:factory, :characters, :expected_sections) do
      [
        [:key,                 ["\n", "\r\n"], 3],
        [:key,                 [' ', ' '],     3],
        [:key_without_comment, [' ', ' '],     2]
      ]
    end

    with_them do
      let!(:key) { create(factory) } # rubocop:disable Rails/SaveBang
      let!(:original_fingerprint) { key.fingerprint }
      let!(:original_fingerprint_sha256) { key.fingerprint_sha256 }

      it 'accepts a key with blank space characters after stripping them' do
        modified_key = key.key.insert(100, characters.first).insert(40, characters.last)
        _, content = modified_key.split

        key.update!(key: modified_key)

        expect(key).to be_valid
        expect(key.key.split.size).to eq(expected_sections)

        expect(content).not_to match(/\s/)
        expect(original_fingerprint).to eq(key.fingerprint)
        expect(original_fingerprint).to eq(key.fingerprint_md5)
        expect(original_fingerprint_sha256).to eq(key.fingerprint_sha256)
      end
    end
  end

  context 'ssh key' do
    subject { build(:key) }

    it_behaves_like 'meets ssh key restrictions'
  end

  context 'callbacks' do
    let(:key) { build(:personal_key) }

    context 'authorized keys file is enabled' do
      before do
        stub_application_setting(authorized_keys_enabled: true)
      end

      it 'adds new key to authorized_file' do
        allow(AuthorizedKeysWorker).to receive(:perform_async)

        key.save!

        # Check after the fact so we have access to Key#id
        expect(AuthorizedKeysWorker).to have_received(:perform_async).with('add_key', key.shell_id, key.key)
      end

      it 'removes key from authorized_file' do
        key.save!

        expect(AuthorizedKeysWorker).to receive(:perform_async).with('remove_key', key.shell_id)

        key.destroy!
      end
    end

    context 'authorized_keys file is disabled' do
      before do
        stub_application_setting(authorized_keys_enabled: false)
      end

      it 'does not add the key on creation' do
        expect(AuthorizedKeysWorker).not_to receive(:perform_async)

        key.save!
      end

      it 'does not remove the key on destruction' do
        key.save!

        expect(AuthorizedKeysWorker).not_to receive(:perform_async)

        key.destroy!
      end
    end
  end

  describe '#key=' do
    let(:valid_key) do
      "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0= dummy@gitlab.com"
    end

    it 'strips white spaces' do
      expect(described_class.new(key: " #{valid_key} ").key).to eq(valid_key)
    end

    it 'invalidates the public_key attribute' do
      key = build(:key)

      original = key.public_key
      key.key = valid_key

      expect(original.key_text).not_to be_nil
      expect(key.public_key.key_text).to eq(valid_key)
    end
  end

  describe '#refresh_user_cache', :use_clean_rails_memory_store_caching do
    context 'when the key belongs to a user' do
      it 'refreshes the keys count cache for the user' do
        expect_any_instance_of(Users::KeysCountService)
          .to receive(:refresh_cache)
          .and_call_original

        key = create(:personal_key)

        expect(Users::KeysCountService.new(key.user).count).to eq(1)
      end
    end

    context 'when the key does not belong to a user' do
      it 'does nothing' do
        expect_any_instance_of(Users::KeysCountService)
          .not_to receive(:refresh_cache)

        create(:key)
      end
    end
  end

  describe '#signing?' do
    it 'returns whether a key can be used for signing' do
      expect(build(:key, usage_type: :signing)).to be_signing
      expect(build(:key, usage_type: :auth_and_signing)).to be_signing
      expect(build(:key, usage_type: :auth)).not_to be_signing
    end
  end
end
