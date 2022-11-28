# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ssh::Signature do
  # ssh-keygen -t ed25519
  let_it_be(:committer_email) { 'ssh-commit-test@example.com' }
  let_it_be(:public_key_text) { 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJKOfqOH0fDde+Ua/1SObkXB1CEDF5M6UfARMpW3F87u' }
  let_it_be_with_reload(:user) { create(:user, email: committer_email) }
  let_it_be_with_reload(:key) { create(:key, usage_type: :signing, key: public_key_text, user: user) }

  let(:signed_text) { 'This message was signed by an ssh key' }

  let(:signature_text) do
    # ssh-keygen -Y sign -n file -f id_test message.txt
    <<~SIG
      -----BEGIN SSH SIGNATURE-----
      U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgko5+o4fR8N175Rr/VI5uRcHUIQ
      MXkzpR8BEylbcXzu4AAAAEZmlsZQAAAAAAAAAGc2hhNTEyAAAAUwAAAAtzc2gtZWQyNTUx
      OQAAAECQa95KgBkgbMwIPNwHRjHu0WYrKvAc5O/FaBXlTDcPWQHi8WRDhbPNN6MqSYLg/S
      hsei6Y8VYPv85StrEHYdoF
      -----END SSH SIGNATURE-----
    SIG
  end

  subject(:signature) do
    described_class.new(
      signature_text,
      signed_text,
      committer_email
    )
  end

  shared_examples 'verified signature' do
    it 'reports verified status' do
      expect(signature.verification_status).to eq(:verified)
    end
  end

  shared_examples 'unverified signature' do
    it 'reports unverified status' do
      expect(signature.verification_status).to eq(:unverified)
    end
  end

  describe 'signature verification' do
    context 'when signature is valid and user email is verified' do
      it_behaves_like 'verified signature'
    end

    context 'when using an RSA key' do
      let(:public_key_text) do
        <<~KEY.delete("\n")
        ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCr3ucg9tLf87S2TxgeDaO4Cs5Mzv7wwi5w
        OnSG8hE/Zj7xzf0kXAYns/dHhPilkQMCulMQuGGprGzDJXZ9WrrVDHgBj2+kLB8cc+XYIb29
        HPsoz5a1T776wWrzs5cw3Vbb0ZEMPG27SfJ+HtIqnIAcgBoRxgP/+I9we7tVxrTuog/9jSzU
        H1IscwfwgKdUrvN5cyhqqxWspwZVlf6s4jaVjC9sKlF7u9CBCxqM2G7GZRKH2sEV2Tw0mT4z
        39UQ5uz9+4hxWChosiQChrT9zSJDGWQm3WGn5ubYPeB/xINEKkFxuEupnSK7l8PQxeLAwlcN
        YHKMkHdO16O6PlpxvcLR1XVy4F12NXCxFjTr8GmFvJTvevf9iuFRmYQpffqm+EMN0shuhPag
        Z1poVK7ZMO49b4HD6csGwDjXEgNAnyi7oPV1WMHVy+xi2j+yaAgiVk50kgTwp9sGkHTiMTM8
        YWjCq+Hb+HXLINmqO5V1QChT7PAFYycmQ0Fe2x39eLLMHy0=
        KEY
      end

      let(:signature_text) do
        <<~SIG
          -----BEGIN SSH SIGNATURE-----
          U1NIU0lHAAAAAQAAAZcAAAAHc3NoLXJzYQAAAAMBAAEAAAGBAKve5yD20t/ztLZPGB4No7
          gKzkzO/vDCLnA6dIbyET9mPvHN/SRcBiez90eE+KWRAwK6UxC4YamsbMMldn1autUMeAGP
          b6QsHxxz5dghvb0c+yjPlrVPvvrBavOzlzDdVtvRkQw8bbtJ8n4e0iqcgByAGhHGA//4j3
          B7u1XGtO6iD/2NLNQfUixzB/CAp1Su83lzKGqrFaynBlWV/qziNpWML2wqUXu70IELGozY
          bsZlEofawRXZPDSZPjPf1RDm7P37iHFYKGiyJAKGtP3NIkMZZCbdYafm5tg94H/Eg0QqQX
          G4S6mdIruXw9DF4sDCVw1gcoyQd07Xo7o+WnG9wtHVdXLgXXY1cLEWNOvwaYW8lO969/2K
          4VGZhCl9+qb4Qw3SyG6E9qBnWmhUrtkw7j1vgcPpywbAONcSA0CfKLug9XVYwdXL7GLaP7
          JoCCJWTnSSBPCn2waQdOIxMzxhaMKr4dv4dcsg2ao7lXVAKFPs8AVjJyZDQV7bHf14sswf
          LQAAAARmaWxlAAAAAAAAAAZzaGE1MTIAAAGUAAAADHJzYS1zaGEyLTUxMgAAAYAXgXpXWw
          A1fYHTUON+e1yrTw8AKB4ymfqpR9Zr1OUmYUKJ9xXvvyNCfKHL6XD14CkMu1Tx8Z3TTPG9
          C6uAXBniKRwwaLVOKffZMshf5sbjcy65KkqBPC7n/cDiCAeoJ8Y05trEDV62+pOpB2lLdv
          pwwg2o0JaoLbdRcKCD0pw1u0O7VDDngTKFZ4ghHrEslxwlFruht1h9hs3rmdITlT0RMNuU
          PHGAIB56u4E4UeoMd3D5rga+4Boj0s6551VgP3vCmcz9ZojPHhTCQdUZU1yHdEBTadYTq6
          UWHhQwDCUDkSNKCRxWo6EyKZQeTakedAt4qkdSpSUCKOJGWKmPOfAm2/sDEmSxffRdxRRg
          QUe8lklyFTZd6U/ZkJ/y7VR46fcSkEqLSLd9jAZT/3HJXbZfULpwsTcvcLcJLkCuzHEaU1
          LRyJBsanLCYHTv7ep5PvIuAngUWrXK2eb7oacVs94mWXfs1PG482Ym4+bZA5u0QliGTVaC
          M2EMhRTf0cqFuA4=
          -----END SSH SIGNATURE-----
        SIG
      end

      before do
        key.update!(key: public_key_text)
      end

      it_behaves_like 'verified signature'
    end

    context 'when signed text is an empty string' do
      let(:signed_text) { '' }
      let(:signature_text) do
        <<~SIG
          -----BEGIN SSH SIGNATURE-----
          U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgko5+o4fR8N175Rr/VI5uRcHUIQ
          MXkzpR8BEylbcXzu4AAAAEZmlsZQAAAAAAAAAGc2hhNTEyAAAAUwAAAAtzc2gtZWQyNTUx
          OQAAAEC1y2I7o3KqKFlnM+MLkhIo+uRX3YQOYCqycfibyfvmkZTcwqMxgNBInBM9pY3VvS
          sbW2iEdgz34agHbi+1BHIM
          -----END SSH SIGNATURE-----
        SIG
      end

      it_behaves_like 'verified signature'
    end

    context 'when signed text is nil' do
      let(:signed_text) { nil }
      let(:signature_text) do
        <<~SIG
          -----BEGIN SSH SIGNATURE-----
          U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgko5+o4fR8N175Rr/VI5uRcHUIQ
          MXkzpR8BEylbcXzu4AAAAEZmlsZQAAAAAAAAAGc2hhNTEyAAAAUwAAAAtzc2gtZWQyNTUx
          OQAAAEC1y2I7o3KqKFlnM+MLkhIo+uRX3YQOYCqycfibyfvmkZTcwqMxgNBInBM9pY3VvS
          sbW2iEdgz34agHbi+1BHIM
          -----END SSH SIGNATURE-----
        SIG
      end

      it_behaves_like 'unverified signature'
    end

    context 'when committer_email is empty' do
      let(:committer_email) { '' }

      it_behaves_like 'unverified signature'
    end

    context 'when committer_email is nil' do
      let(:committer_email) { nil }

      it_behaves_like 'unverified signature'
    end

    context 'when signature_text is empty' do
      let(:signature_text) { '' }

      it_behaves_like 'unverified signature'
    end

    context 'when signature_text is nil' do
      let(:signature_text) { nil }

      it_behaves_like 'unverified signature'
    end

    context 'when user email is not verified' do
      before do
        user.update!(confirmed_at: nil)
      end

      it_behaves_like 'unverified signature'
    end

    context 'when no user exists with the committer email' do
      let(:committer_email) { 'different-email+ssh-commit-test@example.com' }

      it_behaves_like 'unverified signature'
    end

    context 'when signature is invalid' do
      let(:signature_text) do
        # truncated base64
        <<~SIG
          -----BEGIN SSH SIGNATURE-----
          U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgko5+o4fR8N175Rr/VI5uRcHUIQ
          MXkzpR8BEylbcXzu4AAAAEZmlsZQAAAAAAAAAGc2hhNTEyAAAAUwAAAAtzc2gtZWQyNTUx
          OQAAAECQa95KgBkgbMwIPNwHRjHu0WYrKvAc5O/FaBXlTDcPWQHi8WRDhbPNN6MqSYLg/S
          -----END SSH SIGNATURE-----
        SIG
      end

      it_behaves_like 'unverified signature'
    end

    context 'when signature is for a different message' do
      let(:signature_text) do
        <<~SIG
          -----BEGIN SSH SIGNATURE-----
          U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgQtog20+l2pMcPnuoaWXuNpw9u7
          OzPnJzdLUon0+ELNQAAAAEZmlsZQAAAAAAAAAGc2hhNTEyAAAAUwAAAAtzc2gtZWQyNTUx
          OQAAAEB3/B+6c3+XqEuqjiqlVQwQmUdj8WquROtkhdtScEOP8GXcGQx+aaQs5nq4ZJCuu5
          ywcU+4xQaLVpCf7tfGWa4K
          -----END SSH SIGNATURE-----
        SIG
      end

      it_behaves_like 'unverified signature'
    end

    context 'when message has been tampered' do
      let(:signed_text) do
        <<~MSG
          This message was signed by an ssh key
          The pubkey fingerprint is SHA256:RjzeOilYHkiHqz5fefdnrWr8qn5nbroAisuuTMoH9PU
        MSG
      end

      it_behaves_like 'unverified signature'
    end

    context 'when the signing key does not exist in GitLab' do
      context 'when the key is not a signing one' do
        before do
          key.auth!
        end

        it 'reports unknown_key status' do
          expect(signature.verification_status).to eq(:unknown_key)
        end
      end

      context 'when the key is removed' do
        before do
          key.delete
        end

        it 'reports unknown_key status' do
          expect(signature.verification_status).to eq(:unknown_key)
        end
      end
    end

    context 'when key belongs to someone other than the committer' do
      let_it_be(:other_user) { create(:user, email: 'other-user@example.com') }

      let(:committer_email) { other_user.email }

      it 'reports other_user status' do
        expect(signature.verification_status).to eq(:other_user)
      end
    end
  end
end
