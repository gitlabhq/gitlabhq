# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WhatsNewHelper do
  include Devise::Test::ControllerHelpers

  describe '#whats_new_version_digest' do
    let(:digest) { 'digest' }

    it 'calls ReleaseHighlight.most_recent_version_digest' do
      expect(ReleaseHighlight).to receive(:most_recent_version_digest).and_return(digest)

      expect(helper.whats_new_version_digest).to eq(digest)
    end
  end

  describe '#whats_new_most_recent_release_items_count' do
    subject { helper.whats_new_most_recent_release_items_count }

    context 'when recent release items exist' do
      it 'returns the count from the most recent file' do
        allow(ReleaseHighlight).to receive(:most_recent_item_count).and_return(1)

        expect(subject).to eq(1)
      end
    end

    context 'when recent release items do NOT exist' do
      it 'returns nil' do
        allow(ReleaseHighlight).to receive(:most_recent_item_count).and_return(nil)

        expect(subject).to be_nil
      end
    end
  end

  describe '#display_whats_new?' do
    subject { helper.display_whats_new? }

    it 'returns true when gitlab.com' do
      allow(Gitlab).to receive(:org_or_com?).and_return(true)

      expect(subject).to be true
    end

    context 'when self-managed' do
      before do
        allow(Gitlab).to receive(:org_or_com?).and_return(false)
      end

      it 'returns true if user is signed in' do
        sign_in(create(:user))

        expect(subject).to be true
      end

      it "returns false if user isn't signed in" do
        expect(subject).to be false
      end
    end

    context 'depending on whats_new_variant' do
      using RSpec::Parameterized::TableSyntax

      where(:variant, :result) do
        :all_tiers    | true
        :current_tier | true
        :disabled     | false
      end

      with_them do
        it 'returns correct result depending on variant' do
          allow(Gitlab).to receive(:org_or_com?).and_return(true)
          Gitlab::CurrentSettings.update!(whats_new_variant: ApplicationSetting.whats_new_variants[variant])

          expect(subject).to eq(result)
        end
      end
    end
  end

  describe '#whats_new_variants' do
    it 'returns ApplicationSetting.whats_new_variants' do
      expect(helper.whats_new_variants).to eq(ApplicationSetting.whats_new_variants)
    end
  end

  describe '#whats_new_variants_label' do
    let(:labels) do
      [
        helper.whats_new_variants_label('all_tiers'),
        helper.whats_new_variants_label('current_tier'),
        helper.whats_new_variants_label('disabled'),
        helper.whats_new_variants_label(nil)
      ]
    end

    it 'returns different labels depending on variant' do
      expect(labels.uniq.size).to eq(labels.size)
      expect(labels[3]).to be_nil
    end
  end

  describe '#whats_new_variants_description' do
    let(:descriptions) do
      [
        helper.whats_new_variants_description('all_tiers'),
        helper.whats_new_variants_description('current_tier'),
        helper.whats_new_variants_description('disabled'),
        helper.whats_new_variants_description(nil)
      ]
    end

    it 'returns different descriptions depending on variant' do
      expect(descriptions.uniq.size).to eq(descriptions.size)
      expect(descriptions[3]).to be_nil
    end
  end
end
