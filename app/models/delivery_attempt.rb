class DeliveryAttempt < ApplicationRecord
  belongs_to :email

  validates :email, :status, :provider, presence: true

  FINAL_STATUSES = %i[
    delivered
    permanent_failure
    retries_exhausted_failure
  ].freeze

  enum status: {
    sending: 0,
    delivered: 1,
    permanent_failure: 2,
    temporary_failure: 3,
    technical_failure: 4,
    retries_exhausted_failure: 5
  }

  enum provider: { pseudo: 0, notify: 1 }

  def failure?
    permanent_failure? ||
      temporary_failure? ||
      technical_failure? ||
      retries_exhausted_failure?
  end

  def should_report_failure?
    technical_failure?
  end

  def should_remove_subscriber?
    permanent_failure?
  end

  def has_final_status?
    self.class.final_status?(status)
  end

  def self.final_status?(status)
    FINAL_STATUSES.include?(status.to_sym)
  end
end
