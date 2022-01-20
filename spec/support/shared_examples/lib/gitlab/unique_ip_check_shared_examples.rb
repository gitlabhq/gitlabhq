# frozen_string_literal: true

RSpec.shared_examples 'user login operation with unique ip limit' do
  include_context 'unique ips sign in limit' do
    before do
      Gitlab::CurrentSettings.update!(unique_ips_limit_per_user: 1)
    end

    it 'allows user authenticating from the same ip' do
      expect { operation_from_ip('111.221.4.3') }.not_to raise_error
      expect { operation_from_ip('111.221.4.3') }.not_to raise_error
    end

    it 'blocks user authenticating from two distinct ips' do
      expect { operation_from_ip('111.221.4.3') }.not_to raise_error
      expect { operation_from_ip('1.2.2.3') }.to raise_error(Gitlab::Auth::TooManyIps)
    end
  end
end

RSpec.shared_examples 'user login request with unique ip limit' do |success_status = 200|
  include_context 'unique ips sign in limit' do
    before do
      Gitlab::CurrentSettings.update!(unique_ips_limit_per_user: 1)
    end

    it 'allows user authenticating from the same ip' do
      expect(request_from_ip('111.221.4.3')).to have_gitlab_http_status(success_status)
      expect(request_from_ip('111.221.4.3')).to have_gitlab_http_status(success_status)
    end

    it 'blocks user authenticating from two distinct ips' do
      expect(request_from_ip('111.221.4.3')).to have_gitlab_http_status(success_status)
      expect(request_from_ip('1.2.2.3')).to have_gitlab_http_status(:forbidden)
    end
  end
end
