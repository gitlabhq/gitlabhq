# frozen_string_literal: true

RSpec.shared_examples 'releases and group releases resolver' do
  context 'when the user does not have access to the project' do
    let(:current_user) { public_user }

    it 'returns an empty response' do
      expect(resolve_releases).to be_blank
    end
  end

  context "when the user has full access to the project's releases" do
    let(:current_user) { developer }

    it 'returns all releases associated to the project' do
      expect(resolve_releases).to match_array(all_releases)
    end

    describe 'when order_by is released_at' do
      context 'with sort: desc' do
        let(:args) { { sort: :released_at_desc } }

        it 'returns the releases ordered by released_at in descending order' do
          expect(resolve_releases.to_a)
            .to match_array(all_releases)
            .and be_sorted(:released_at, :desc)
        end
      end

      context 'with sort: asc' do
        let(:args) { { sort: :released_at_asc } }

        it 'returns the releases ordered by released_at in ascending order' do
          expect(resolve_releases.to_a)
            .to match_array(all_releases)
            .and be_sorted(:released_at, :asc)
        end
      end
    end
  end
end
