# frozen_string_literal: true

RSpec.describe Millrace::RateLimit do
  let(:subject) do
    described_class.new(
      name: "test",
      rate: 10,
      window: 2,
      penalty: penalty,
    )
  end

  let(:penalty) { 1 }

  let(:controller) do
    double(:controller, request: double(:request, remote_ip: to_s))
  end

  describe "#before" do
    it "rate limits" do
      # Fill the bucket
      20.times { subject.before(controller) }

      # hit the threshold and get a penalty
      expect { subject.before(controller) }.to raise_error Millrace::RateLimited

      sleep 1
      # Still blocked for the penalty duration
      expect { subject.before(controller) }.to raise_error Millrace::RateLimited

      # Not blocked after the penalty duration is over
      sleep 1
      subject.before(controller)
    end

    it "returns an exeption with the correct name" do
      # Fill the bucket
      20.times { subject.before(controller) }

      # hit the threshold and get an error
      expect { subject.before(controller) }.to raise_error do |exception|
        expect(exception.limit_name).to eq "test"
      end
    end

    it "returns an exeption with the correct retry time" do
      # Fill the bucket
      20.times { subject.before(controller) }

      # hit the threshold and get an error
      expect { subject.before(controller) }.to raise_error do |exception|
        expect(exception.retry_after).to eq 1
      end
    end

    context "a longer penalty" do
      let(:penalty) { 10 }

      it "returns an exeption with the correct retry time" do
        # Fill the bucket
        20.times { subject.before(controller) }

        # hit the threshold and get an error
        expect { subject.before(controller) }.to raise_error do |exception|
          expect(exception.retry_after).to eq 10
        end
      end
    end

    context "additional requests" do
      let(:penalty) { 0 }

      it "returns an exeption with the correct retry time" do
        # Fill the bucket
        40.times do
          subject.before(controller)
        # Keep making requests even though we are rate limited
        rescue Millrace::RateLimited
          nil
        end

        # hit the threshold and get an error
        expect { subject.before(controller) }.to raise_error do |exception|
          expect(exception.retry_after).to eq 2
        end
      end
    end
  end
end
