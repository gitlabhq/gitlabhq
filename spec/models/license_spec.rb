require "spec_helper"

describe License do
  let(:gl_license)  { build(:gitlab_license) }
  let(:license)     { build(:license, data: gl_license.export) }

  describe "Validation" do
    describe "Valid license" do
      context "when the license is provided" do
        it "is valid" do
          expect(license).to be_valid
        end
      end

      context "when no license is provided" do
        before do
          license.data = nil
        end

        it "is invalid" do
          expect(license).not_to be_valid
        end
      end
    end

    describe "Historical active user count" do
      let(:active_user_count) { User.active.count + 10 }
      let(:date)              { License.current.starts_at }
      let!(:historical_data)  { HistoricalData.create!(date: date, active_user_count: active_user_count) }

      context "when there is no active user count restriction" do
        it "is valid" do
          expect(license).to be_valid
        end
      end

      context "when the active user count restriction is exceeded" do
        before do
          gl_license.restrictions = { active_user_count: active_user_count - 1 }
        end

        context "when the license started" do
          it "is invalid" do
            expect(license).not_to be_valid
          end
        end

        context "after the license started" do
          let(:date) { Date.today }

          it "is valid" do
            expect(license).to be_valid
          end
        end

        context "in the year before the license started" do
          let(:date) { License.current.starts_at - 6.months }

          it "is invalid" do
            expect(license).not_to be_valid
          end
        end

        context "earlier than a year before the license started" do
          let(:date) { License.current.starts_at - 2.years }

          it "is valid" do
            expect(license).to be_valid
          end
        end
      end

      context "when the active user count restriction is not exceeded" do
        before do
          gl_license.restrictions = { active_user_count: active_user_count + 1 }
        end

        it "is valid" do
          expect(license).to be_valid
        end
      end

      context "when the active user count is met exactly" do
        it "is valid" do
          active_user_count = 100
          gl_license.restrictions = { active_user_count: active_user_count }

          expect(license).to be_valid
        end
      end
    end

    describe "Not expired" do
      context "when the license doesn't expire" do
        it "is valid" do
          expect(license).to be_valid
        end
      end

      context "when the license has expired" do
        before do
          gl_license.expires_at = Date.yesterday
        end

        it "is valid" do
          expect(license).not_to be_valid
        end

      end

      context "when the license has yet to expire" do
        before do
          gl_license.expires_at = Date.tomorrow
        end

        it "is valid" do
          expect(license).to be_valid
        end
      end
    end
  end

  describe "Class methods" do
    let!(:license) { License.last }

    before do
      License.reset_current
      allow(License).to receive(:last).and_return(license)
    end

    describe ".current" do
      context "when there is no license" do
        let!(:license) { nil }

        it "returns nil" do
          expect(License.current).to be_nil
        end
      end

      context "when the license is invalid" do
        before do
          allow(license).to receive(:valid?).and_return(false)
        end

        it "returns nil" do
          expect(License.current).to be_nil
        end
      end

      context "when the license is valid" do
        it "returns the license" do
          expect(License.current)
        end
      end
    end

    describe ".block_changes?" do
      context "when there is no current license" do
        before do
          allow(License).to receive(:current).and_return(nil)
        end

        it "returns true" do
          expect(License.block_changes?).to be_truthy
        end
      end

      context "when the current license is set to block changes" do
        before do
          allow(license).to receive(:block_changes?).and_return(true)
        end

        it "returns true" do
          expect(License.block_changes?).to be_truthy
        end
      end

      context "when the current license doesn't block changes" do
        it "returns false" do
          expect(License.block_changes?).to be_falsey
        end
      end
    end
  end

  describe "#license" do
    context "when no data is provided" do
      before do
        license.data = nil
      end

      it "returns nil" do
        expect(license.license).to be_nil
      end
    end

    context "when corrupt license data is provided" do
      before do
        license.data = "whatever"
      end

      it "returns nil" do
        expect(license.license).to be_nil
      end
    end

    context "when valid license data is provided" do
      it "returns the license" do
        expect(license.license).not_to be_nil
      end
    end
  end

  describe 'reading add-ons' do
    describe '#add_ons' do
      context "without add-ons" do
        it 'returns an empty Hash' do
          license = build_license_with_add_ons({})

          expect(license.add_ons).to eq({})
        end
      end

      context "with add-ons" do
        it 'returns all available add-ons' do
          license = build_license_with_add_ons({ 'support' => 1, 'custom-domain' => 2 })

          expect(license.add_ons.keys).to include('support', 'custom-domain')
        end

        it 'can return details about a single add-on' do
          license = build_license_with_add_ons({ 'custom-domain' => 2 })

          expect(license.add_ons['custom-domain']).to eq(2)
        end
      end
    end

    describe '#add_on?' do
      it 'returns true if add-on exists and have a quantity greater than 0' do
        license = build_license_with_add_ons({ 'support' => 1 })

        expect(license.add_on?('support')).to eq(true)
      end

      it 'returns false if add-on exists but have a quantity of 0' do
        license = build_license_with_add_ons({ 'support' => 0 })

        expect(license.add_on?('support')).to eq(false)
      end

      it 'returns false if add-on does not exists' do
        license = build_license_with_add_ons({})

        expect(license.add_on?('support')).to eq(false)
      end
    end

    def build_license_with_add_ons(add_ons)
      gl_license = build(:gitlab_license, restrictions: { add_ons: add_ons })
      build(:license, data: gl_license.export)
    end
  end

end
