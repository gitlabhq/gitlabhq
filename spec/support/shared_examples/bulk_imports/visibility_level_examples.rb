# frozen_string_literal: true

RSpec.shared_examples 'visibility level settings' do
  context 'when public' do
    let(:data) { { 'visibility' => 'public' } }

    context 'when destination is a public group' do
      let(:destination_group) { create(:group, :public) }

      it 'sets visibility level to public' do
        expect(transformed_data[:visibility_level]).to eq(Gitlab::VisibilityLevel::PUBLIC)
      end
    end

    context 'when destination is a internal group' do
      let(:destination_group) { create(:group, :internal) }

      it 'sets visibility level to internal' do
        expect(transformed_data[:visibility_level]).to eq(Gitlab::VisibilityLevel::INTERNAL)
      end
    end

    context 'when destination is a private group' do
      let(:destination_group) { create(:group, :private) }

      it 'sets visibility level to private' do
        expect(transformed_data[:visibility_level]).to eq(Gitlab::VisibilityLevel::PRIVATE)
      end
    end
  end

  context 'when internal' do
    let(:data) { { 'visibility' => 'internal' } }

    context 'when destination is a public group' do
      let(:destination_group) { create(:group, :public) }

      it 'sets visibility level to internal' do
        expect(transformed_data[:visibility_level]).to eq(Gitlab::VisibilityLevel::INTERNAL)
      end
    end

    context 'when destination is a internal group' do
      let(:destination_group) { create(:group, :internal) }

      it 'sets visibility level to internal' do
        expect(transformed_data[:visibility_level]).to eq(Gitlab::VisibilityLevel::INTERNAL)
      end
    end

    context 'when destination is a private group' do
      let(:destination_group) { create(:group, :private) }

      it 'sets visibility level to private' do
        expect(transformed_data[:visibility_level]).to eq(Gitlab::VisibilityLevel::PRIVATE)
      end
    end
  end

  context 'when private' do
    let(:data) { { 'visibility' => 'private' } }

    context 'when destination is a public group' do
      let(:destination_group) { create(:group, :public) }

      it 'sets visibility level to private' do
        expect(transformed_data[:visibility_level]).to eq(Gitlab::VisibilityLevel::PRIVATE)
      end
    end

    context 'when destination is a internal group' do
      let(:destination_group) { create(:group, :internal) }

      it 'sets visibility level to private' do
        expect(transformed_data[:visibility_level]).to eq(Gitlab::VisibilityLevel::PRIVATE)
      end
    end

    context 'when destination is a private group' do
      let(:destination_group) { create(:group, :private) }

      it 'sets visibility level to private' do
        expect(transformed_data[:visibility_level]).to eq(Gitlab::VisibilityLevel::PRIVATE)
      end
    end
  end
end
