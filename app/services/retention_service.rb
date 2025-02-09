# frozen_string_literal: true

class RetentionService
  def self.send_emails
    EmailRetention.find_each do |email_retention|
      end_of_2022 = Date.new(2022, 12, 01)
      needs = Need.with_exchange
        .min_closed_with_help_at(end_of_2022..email_retention.waiting_time.months.ago)
        .where(subject: email_retention.subject, retention_sent_at: nil)

      needs.each do |need|
        CompanyMailer.intelligent_retention(need, email_retention).deliver_later
        need.update(retention_sent_at: Time.zone.now)
      end
    end
  end
end
