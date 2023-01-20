# frozen_string_literal: true

RSpec.shared_examples 'rejects Debian access with unknown container id' do |anonymous_status, auth_method|
  context 'with an unknown container' do
    let(:container) { double(id: non_existing_record_id) }

    context 'as anonymous' do
      it_behaves_like 'Debian packages GET request', anonymous_status, nil
    end

    context 'as authenticated user' do
      include_context 'Debian repository auth headers', :not_a_member, auth_method do
        it_behaves_like 'Debian packages GET request', :not_found, nil
      end
    end
  end
end
