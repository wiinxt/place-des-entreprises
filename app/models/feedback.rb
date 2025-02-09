# == Schema Information
#
# Table name: feedbacks
#
#  id                :bigint(8)        not null, primary key
#  category          :enum             not null
#  description       :text
#  feedbackable_type :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  feedbackable_id   :bigint(8)
#  user_id           :bigint(8)
#
# Indexes
#
#  index_feedbacks_on_category                               (category)
#  index_feedbacks_on_feedbackable_type_and_feedbackable_id  (feedbackable_type,feedbackable_id)
#  index_feedbacks_on_user_id                                (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

class Feedback < ApplicationRecord
  enum category: {
    need: 'need',
    need_reminder: 'need_reminder',
    expert_reminder: 'expert_reminder',
    solicitation: 'solicitation'
  }, _prefix: true

  ## Associations
  #
  belongs_to :feedbackable, polymorphic: true, touch: true
  belongs_to :user, inverse_of: :feedbacks

  ## Validations
  #
  validates :description, presence: true

  ##
  #

  def notify_for_need!
    return unless category_need?
    persons_to_notify.each do |person|
      UserMailer.match_feedback(self, person)&.deliver_later
    end
  end

  # Notify experts of this need
  # don't send an email to their personal address
  def persons_to_notify
    users_and_experts_to_notify = self.need.matches.where(status: [:taking_care, :done_not_reachable]).map(&:expert)

    # don’t notify the author themselves
    users_and_experts_to_notify -= self.user.experts

    # Notify the advisor only if he's not the author or the author is not an admin
    users_and_experts_to_notify << self.need.advisor if (!self.user.is_admin? && self.user != self.need.advisor)

    users_and_experts_to_notify
  end

  def need
    feedbackable if feedbackable_type == "Need"
  end

  def solicitation
    feedbackable if feedbackable_type == "Solicitation"
  end

  def expert
    feedbackable if feedbackable_type == "Expert"
  end
end
