# == Schema Information
#
# Table name: needs
#
#  id                      :bigint(8)        not null, primary key
#  archived_at             :datetime
#  content                 :text
#  matches_count           :integer
#  satisfaction_email_sent :boolean          default(FALSE), not null
#  status                  :enum             default("diagnosis_not_complete"), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  diagnosis_id            :bigint(8)        not null
#  subject_id              :bigint(8)        not null
#
# Indexes
#
#  index_needs_on_archived_at                  (archived_at)
#  index_needs_on_diagnosis_id                 (diagnosis_id)
#  index_needs_on_status                       (status)
#  index_needs_on_subject_id                   (subject_id)
#  index_needs_on_subject_id_and_diagnosis_id  (subject_id,diagnosis_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (diagnosis_id => diagnoses.id)
#  fk_rails_...  (subject_id => subjects.id)
#

class Need < ApplicationRecord
  ##
  #
  include Archivable

  enum status: {
    diagnosis_not_complete: 'diagnosis_not_complete',
      quo: 'quo',
      taking_care: 'taking_care',
      done: 'done',
      done_no_help: 'done_no_help',
      done_not_reachable: 'done_not_reachable',
      not_for_me: 'not_for_me'
  }, _prefix: true

  ## Associations
  #
  belongs_to :diagnosis, inverse_of: :needs, touch: true
  belongs_to :subject, inverse_of: :needs
  has_many :matches, dependent: :destroy, inverse_of: :need
  has_many :feedbacks, dependent: :destroy, as: :feedbackable
  has_many :reminders_actions, inverse_of: :need, dependent: :destroy
  has_one :company_satisfaction, dependent: :destroy, inverse_of: :need

  ## Validations
  #
  validates :diagnosis, presence: true
  validates :subject, uniqueness: { scope: :diagnosis_id }

  accepts_nested_attributes_for :matches, allow_destroy: true

  ## Callbacks
  #
  after_touch :update_status

  ## Through Associations
  #
  # :diagnosis
  has_one :facility, through: :diagnosis, inverse_of: :needs
  has_one :company, through: :diagnosis, inverse_of: :needs
  has_one :solicitation, through: :diagnosis, inverse_of: :needs
  has_one :advisor, through: :diagnosis, inverse_of: :sent_needs

  # :matches
  has_many :experts, -> { distinct }, through: :matches, inverse_of: :received_needs

  # :facility
  has_many :facility_territories, through: :facility, source: :territories, inverse_of: :needs

  # :advisor
  has_one :advisor_antenne, through: :advisor, source: :antenne, inverse_of: :sent_needs
  has_one :advisor_institution, through: :advisor, source: :institution, inverse_of: :sent_needs

  # :experts
  has_many :expert_antennes, through: :experts, source: :antenne, inverse_of: :received_needs
  has_many :expert_institutions, through: :experts, source: :institution, inverse_of: :received_needs
  has_many :contacted_users, through: :experts, source: :users, inverse_of: :received_needs

  # :subject
  has_one :theme, through: :subject, inverse_of: :needs

  ## Scopes
  #
  EXPERT_ABANDONED_DELAY = 14.days
  REMINDER_DELAY = 7.days
  REMINDER_TO_RECALL_DELAY = 14.days
  REMINDER_INSTITUTIONS_DELAY = 21.days
  REMINDER_ABANDONED_DELAY = 30.days

  scope :made_in, -> (date_range) do
    joins(:diagnosis)
      .where(diagnoses: { happened_on: date_range })
      .distinct
  end

  scope :ordered_for_interview, -> do
    left_outer_joins(:subject)
      .merge(Subject.ordered_for_interview)
  end

  scope :diagnosis_completed, -> do
    joins(:diagnosis)
      .merge(Diagnosis.completed)
  end

  scope :abandoned_quo_not_taken, -> do
    status_quo
      .archived(false)
      .abandoned
  end

  scope :reminders_to_process, -> do
    no_help_provided
      .archived(false)
      .reminder
  end

  scope :reminder_quo_not_taken, -> do
    query = no_help_provided
      .archived(false)
      .reminder
      .left_outer_joins(:reminders_actions)
    query.exclude_needs_with_reminders_action(:poke).distinct
  end

  scope :reminder_to_recall, -> do
    query = no_help_provided
      .archived(false)
      .in_reminder_to_recall_time_range
      .left_outer_joins(:reminders_actions)
    query.exclude_needs_with_reminders_action(:recall).distinct
  end

  scope :reminder_institutions, -> do
    query = no_help_provided
      .archived(false)
      .reminder_institutions_delay
      .left_outer_joins(:reminders_actions)
    query.exclude_needs_with_reminders_action(:warn).distinct
  end

  scope :exclude_needs_with_reminders_action, -> (category) do
    where.not(reminders_actions: { category: category })
      .or(self.where(reminders_actions: { id: nil }))
  end

  scope :abandoned_without_taking_care, -> do
    with_matches_only_in_status([:quo, :not_for_me])
      .archived(false)
      .reminder_abandoned
      .distinct
      .or(left_outer_joins(:matches).rejected.distinct)
  end

  scope :abandoned_taken_not_done, -> do
    status_taking_care
      .archived(false)
      .abandoned
  end

  scope :rejected, -> do
    status_not_for_me
      .archived(false)
  end

  scope :min_closed_at, -> (range) do
    joins(:matches)
      .merge(Match.status_done)
      .group(:id)
      .having("MIN(matches.closed_at) BETWEEN ? AND ?", range.begin, range.end)
  end

  scope :reminder, -> { left_outer_joins(:matches).where('matches.created_at BETWEEN ? AND ?', REMINDER_TO_RECALL_DELAY.ago, REMINDER_DELAY.ago) }

  scope :in_reminder_to_recall_time_range, -> { left_outer_joins(:matches).where('matches.created_at BETWEEN ? AND ?',REMINDER_INSTITUTIONS_DELAY.ago, REMINDER_TO_RECALL_DELAY.ago) }

  scope :reminder_institutions_delay, -> { left_outer_joins(:matches).where('matches.created_at BETWEEN ? AND ?', REMINDER_ABANDONED_DELAY.ago, REMINDER_INSTITUTIONS_DELAY.ago) }

  scope :reminder_abandoned, -> { left_outer_joins(:matches).where('matches.created_at < ?', REMINDER_ABANDONED_DELAY.ago) }

  # For Reminders, find Needs without taking care since EXPERT_ABANDONED_DELAY
  scope :abandoned, -> { joins(:matches).where("matches.created_at < ?", EXPERT_ABANDONED_DELAY.ago) }

  scope :with_some_matches_in_status, -> (status) do # can be an array
    joins(:matches).where(matches: Match.unscoped.where(status: status)).distinct
  end

  scope :with_matches_only_in_status, -> (status) do # can be an array
    left_outer_joins(:matches).where.not(matches: Match.unscoped.where.not(status: status)).distinct
  end

  scope :no_help_provided, -> { where(status: %w[quo not_for_me done_no_help done_not_reachable]) }

  scope :active, -> do
    archived(false)
      .with_matches_only_in_status([:quo, :taking_care, :not_for_me])
      .with_some_matches_in_status([:quo, :taking_care])
  end

  scope :by_territory, -> (territory) do
    joins(:diagnosis).where(diagnoses: { facility: territory&.facilities })
  end

  ##
  #
  def to_s
    "#{company} : #{subject}"
  end

  def initial_matches_at
    matches.pluck(:created_at).min
  end

  def abandoned?
    updated_at < EXPERT_ABANDONED_DELAY.ago
  end

  def quo_experts
    Expert.joins(:received_matches).merge(matches.status_quo)
  end

  def update_status
    self.matches.reload # Make sure the matches are fresh from DB; see #1421
    matches_status = matches.pluck(:status).map(&:to_sym)

    if !diagnosis.step_completed?
      status = :diagnosis_not_complete
    elsif matches_status.include?(:done)
      status = :done
    elsif matches_status.include?(:taking_care)
      status = :taking_care
    elsif matches_status.include?(:done_not_reachable)
      status = :done_not_reachable
    elsif matches_status.include?(:done_no_help)
      status = :done_no_help
    elsif matches_status.include?(:quo)
      status = :quo
    else
      status = :not_for_me
    end
    self.update(status: status)
  end
end
