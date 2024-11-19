# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SSHPublicKey, :lib, fips_mode: false do
  let(:key) { attributes_for(:rsa_key_2048)[:key] }
  let(:public_key) { described_class.new(key) }

  describe '.technology(name)' do
    it 'returns nil for an unrecognised name' do
      expect(described_class.technology(:foo)).to be_nil
    end

    where(:name) do
      [:rsa, :dsa, :ecdsa, :ed25519, :ecdsa_sk, :ed25519_sk]
    end

    with_them do
      it { expect(described_class.technology(name).name).to eq(name) }
      it { expect(described_class.technology(name.to_s).name).to eq(name) }
    end

    context 'FIPS mode', :fips_mode do
      where(:name) do
        [:rsa, :ecdsa, :ed25519, :ecdsa_sk, :ed25519_sk]
      end

      with_them do
        it { expect(described_class.technology(name).name).to eq(name) }
        it { expect(described_class.technology(name.to_s).name).to eq(name) }
      end
    end
  end

  describe '.supported_types' do
    it 'returns array with the names of supported technologies' do
      expect(described_class.supported_types).to eq(
        [:rsa, :dsa, :ecdsa, :ed25519, :ecdsa_sk, :ed25519_sk]
      )
    end

    context 'FIPS mode', :fips_mode do
      it 'returns array with the names of supported technologies' do
        expect(described_class.supported_types).to eq(
          [:rsa, :dsa, :ecdsa, :ed25519, :ecdsa_sk, :ed25519_sk]
        )
      end
    end
  end

  describe '.supported_sizes(name)' do
    where(:name, :sizes) do
      [
        [:rsa, [1024, 2048, 3072, 4096]],
        [:dsa, [1024, 2048, 3072]],
        [:ecdsa, [256, 384, 521]],
        [:ed25519, [256]],
        [:ecdsa_sk, [256]],
        [:ed25519_sk, [256]]
      ]
    end

    with_them do
      it { expect(described_class.supported_sizes(name)).to eq(sizes) }
      it { expect(described_class.supported_sizes(name.to_s)).to eq(sizes) }
    end

    context 'FIPS mode', :fips_mode do
      where(:name, :sizes) do
        [
          [:rsa, [3072, 4096]],
          [:dsa, []],
          [:ecdsa, [256, 384, 521]],
          [:ed25519, [256]],
          [:ecdsa_sk, [256]],
          [:ed25519_sk, [256]]
        ]
      end

      with_them do
        it { expect(described_class.supported_sizes(name)).to eq(sizes) }
        it { expect(described_class.supported_sizes(name.to_s)).to eq(sizes) }
      end
    end
  end

  describe '.supported_algorithms' do
    it 'returns all supported algorithms' do
      expect(described_class.supported_algorithms).to eq(
        %w[
          ssh-rsa
          ssh-dss
          ecdsa-sha2-nistp256 ecdsa-sha2-nistp384 ecdsa-sha2-nistp521
          ssh-ed25519
          sk-ecdsa-sha2-nistp256@openssh.com
          sk-ssh-ed25519@openssh.com
        ]
      )
    end

    context 'FIPS mode', :fips_mode do
      it 'returns all supported algorithms' do
        expect(described_class.supported_algorithms).to eq(
          %w[
            ssh-rsa
            ssh-dss
            ecdsa-sha2-nistp256 ecdsa-sha2-nistp384 ecdsa-sha2-nistp521
            ssh-ed25519
            sk-ecdsa-sha2-nistp256@openssh.com
            sk-ssh-ed25519@openssh.com
          ]
        )
      end
    end
  end

  describe '.supported_algorithms_for_name' do
    where(:name, :algorithms) do
      [
        [:rsa, %w[ssh-rsa]],
        [:dsa, %w[ssh-dss]],
        [:ecdsa, %w[ecdsa-sha2-nistp256 ecdsa-sha2-nistp384 ecdsa-sha2-nistp521]],
        [:ed25519, %w[ssh-ed25519]],
        [:ecdsa_sk, %w[sk-ecdsa-sha2-nistp256@openssh.com]],
        [:ed25519_sk, %w[sk-ssh-ed25519@openssh.com]]
      ]
    end

    with_them do
      it "returns all supported algorithms for #{params[:name]}" do
        expect(described_class.supported_algorithms_for_name(name)).to eq(algorithms)
        expect(described_class.supported_algorithms_for_name(name.to_s)).to eq(algorithms)
      end
    end

    context 'FIPS mode', :fips_mode do
      where(:name, :algorithms) do
        [
          [:rsa, %w[ssh-rsa]],
          [:dsa, %w[ssh-dss]],
          [:ecdsa, %w[ecdsa-sha2-nistp256 ecdsa-sha2-nistp384 ecdsa-sha2-nistp521]],
          [:ed25519, %w[ssh-ed25519]],
          [:ecdsa_sk, %w[sk-ecdsa-sha2-nistp256@openssh.com]],
          [:ed25519_sk, %w[sk-ssh-ed25519@openssh.com]]
        ]
      end

      with_them do
        it "returns all supported algorithms for #{params[:name]}" do
          expect(described_class.supported_algorithms_for_name(name)).to eq(algorithms)
          expect(described_class.supported_algorithms_for_name(name.to_s)).to eq(algorithms)
        end
      end
    end
  end

  describe '.sanitize(key_content)' do
    let(:content) { build(:key).key }

    context 'when key has blank space characters' do
      it 'removes the extra blank space characters' do
        unsanitized = content.insert(100, "\n")
          .insert(40, "\r\n")
          .insert(30, ' ')

        sanitized = described_class.sanitize(unsanitized)
        _, body = sanitized.split

        expect(sanitized).not_to eq(unsanitized)
        expect(body).not_to match(/\s/)
      end
    end

    context "when key doesn't have blank space characters" do
      it "doesn't modify the content" do
        sanitized = described_class.sanitize(content)

        expect(sanitized).to eq(content)
      end
    end

    context "when key is invalid" do
      it 'returns the original content' do
        unsanitized = "ssh-foo any content=="
        sanitized = described_class.sanitize(unsanitized)

        expect(sanitized).to eq(unsanitized)
      end
    end
  end

  describe '#valid?' do
    subject { public_key }

    context 'with a valid SSH key' do
      where(:factory) do
        %i[rsa_key_2048
           rsa_key_4096
           rsa_key_5120
           rsa_key_8192
           dsa_key_2048
           ecdsa_key_256
           ed25519_key_256
           ecdsa_sk_key_256
           ed25519_sk_key_256]
      end

      with_them do
        let(:key) { attributes_for(factory)[:key] }

        it { is_expected.to be_valid }

        context 'when key begins with options' do
          let(:key) { "restrict,command='dump /home' #{attributes_for(factory)[:key]}" }

          it { is_expected.to be_valid }
        end

        context 'when key is in known_hosts format' do
          context "when key begins with 'example.com'" do
            let(:key) { "example.com #{attributes_for(factory)[:key]}" }

            it { is_expected.to be_valid }
          end

          context "when key begins with '@revoked other.example.com'" do
            let(:key) { "@revoked other.example.com #{attributes_for(factory)[:key]}" }

            it { is_expected.to be_valid }
          end
        end
      end
    end

    context 'with an invalid SSH key' do
      let(:key) { 'this is not a key' }

      it { is_expected.not_to be_valid }
    end

    context 'when an unsupported SSH key algorithm' do
      let(:key) { "unsupported-#{attributes_for(:rsa_key_2048)[:key]}" }

      it { is_expected.not_to be_valid }
    end
  end

  shared_examples 'raises error when the key is represented by a class that is not in the list of supported technologies' do
    context 'when the key is represented by a class that is not in the list of supported technologies' do
      it 'raises error' do
        klass = Class.new
        key = klass.new

        allow(public_key).to receive(:key).and_return(key)

        expect { subject }.to raise_error("Unsupported key type: #{key.class}")
      end
    end

    context 'when the key is represented by a subclass of the class that is in the list of supported technologies' do
      it 'raises error' do
        rsa_subclass = Class.new(described_class.technology(:rsa).key_class) do
          def initialize; end
        end

        key = rsa_subclass.new

        allow(public_key).to receive(:key).and_return(key)

        expect { subject }.to raise_error("Unsupported key type: #{key.class}")
      end
    end
  end

  describe '#type' do
    subject { public_key.type }

    where(:factory, :type) do
      [
        [:rsa_key_2048, :rsa],
        [:dsa_key_2048, :dsa],
        [:ecdsa_key_256, :ecdsa],
        [:ed25519_key_256, :ed25519],
        [:ecdsa_sk_key_256, :ecdsa_sk],
        [:ed25519_sk_key_256, :ed25519_sk]
      ]
    end

    with_them do
      let(:key) { attributes_for(factory)[:key] }

      it { is_expected.to eq(type) }
    end

    context 'with an invalid SSH key' do
      let(:key) { 'this is not a key' }

      it { is_expected.to be_nil }
    end

    include_examples 'raises error when the key is represented by a class that is not in the list of supported technologies'
  end

  describe '#bits' do
    subject { public_key.bits }

    where(:factory, :bits) do
      [
        [:rsa_key_2048, 2048],
        [:rsa_key_4096, 4096],
        [:rsa_key_5120, 5120],
        [:rsa_key_8192, 8192],
        [:dsa_key_2048, 2048],
        [:ecdsa_key_256, 256],
        [:ed25519_key_256, 256],
        [:ecdsa_sk_key_256, 256],
        [:ed25519_sk_key_256, 256]
      ]
    end

    with_them do
      let(:key) { attributes_for(factory)[:key] }

      it { is_expected.to eq(bits) }
    end

    context 'with an invalid SSH key' do
      let(:key) { 'this is not a key' }

      it { is_expected.to be_nil }
    end

    include_examples 'raises error when the key is represented by a class that is not in the list of supported technologies'
  end

  describe '#banned?' do
    subject { public_key.banned? }

    where(:key) do
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
      it { is_expected.to be true }
    end

    context 'with a valid SSH key' do
      let(:key) { attributes_for(:rsa_key_2048)[:key] }

      it { is_expected.to be false }
    end

    context 'with an invalid SSH key' do
      let(:key) { 'this is not a key' }

      it { is_expected.to be false }
    end
  end

  describe '#fingerprint' do
    subject { public_key.fingerprint }

    where(:factory, :fingerprint) do
      [
        [:rsa_key_2048, '58:a8:9d:cd:1f:70:f8:5a:d9:e4:24:8e:da:89:e4:fc'],
        [:rsa_key_4096, 'df:73:db:29:3c:a5:32:cf:09:17:7e:8e:9d:de:d7:f7'],
        [:rsa_key_5120, 'fe:fa:3a:4d:7d:51:ec:bf:c7:64:0c:96:d0:17:8a:d0'],
        [:rsa_key_8192, 'fb:53:7f:e9:2f:f7:17:aa:c8:32:52:06:8e:05:e2:82'],
        [:dsa_key_2048, 'c8:85:1e:df:44:0f:20:00:3c:66:57:2b:21:10:5a:27'],
        [:ecdsa_key_256, '67:a3:a9:7d:b8:e1:15:d4:80:40:21:34:bb:ed:97:38'],
        [:ed25519_key_256, 'e6:eb:45:8a:3c:59:35:5f:e9:5b:80:12:be:7e:22:73'],
        [:ecdsa_sk_key_256, '56:b9:bc:99:3d:2f:cf:63:6b:70:d8:f9:40:7e:09:4c'],
        [:ed25519_sk_key_256, 'f9:a0:64:0b:4b:72:72:0e:62:92:d7:04:14:74:1c:c9']
      ]
    end

    with_them do
      let(:key) { attributes_for(factory)[:key] }

      it { is_expected.to eq(fingerprint) }
    end

    context 'with an invalid SSH key' do
      let(:key) { 'this is not a key' }

      it { is_expected.to be_nil }
    end
  end

  describe '#fingerprint_sha256' do
    subject { public_key.fingerprint_sha256 }

    where(:factory, :fingerprint_sha256) do
      [
        [:rsa_key_2048, 'SHA256:GdtgO0eHbwLB+mK47zblkoXujkqKRZjgMQrHH6Kks3E'],
        [:rsa_key_4096, 'SHA256:ByDU7hQ1JB95l6p53rHrffc4eXvEtqGUtQhS+Dhyy7g'],
        [:rsa_key_5120, 'SHA256:PCCupLbFHScm4AbEufbGDvhBU27IM0MVAor715qKQK8'],
        [:rsa_key_8192, 'SHA256:CtHFQAS+9Hb8z4vrv4gVQPsHjNN0WIZhWODaB1mQLs4'],
        [:dsa_key_2048, 'SHA256:+a3DQ7cU5GM+gaYOfmc0VWNnykHQSuth3VRcCpWuYNI'],
        [:ecdsa_key_256, 'SHA256:C+I5k3D+IGeM6k5iBR1ZsphqTKV+7uvL/XZ5hcrTr7g'],
        [:ed25519_key_256, 'SHA256:DCKAjzxWrdOTjaGKBBjtCW8qY5++GaiAJflrHPmp6W0'],
        [:ecdsa_sk_key_256, 'SHA256:N0sNKBgWKK8usPuPegtgzHQQA9vQ/dRhAEhwFDAnLA4'],
        [:ed25519_sk_key_256, 'SHA256:U8IKRkIHed6vFMTflwweA3HhIf2DWgZ8EFTm9fgwOUk']
      ]
    end

    with_them do
      let(:key) { attributes_for(factory)[:key] }

      it { is_expected.to eq(fingerprint_sha256) }
    end

    context 'with an invalid SSH key' do
      let(:key) { 'this is not a key' }

      it { is_expected.to be_nil }
    end
  end

  describe '#key_text' do
    where(:key_value) do
      [
        'this is not a key',
        nil
      ]
    end

    with_them do
      let(:key) { key_value }

      it 'carries the unmodified key data' do
        expect(public_key.key_text).to eq(key)
      end
    end
  end
end
