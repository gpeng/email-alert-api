require 'rails_helper'

RSpec.describe ContentChange do
  let(:content_change) { create(:content_change) }
  describe "mark_processed!" do
    it "sets processed_at" do
      Timecop.freeze do
        expect { content_change.mark_processed! }
          .to change { content_change.processed_at }
          .from(nil)
          .to(Time.now)
      end
    end
  end
end
