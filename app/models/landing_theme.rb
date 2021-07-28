class LandingTheme< ApplicationRecord
  ## Associations
  #
  has_many :landing_joint_themes, -> { order(:position) }, inverse_of: :landing_theme, dependent: :destroy
  has_many :landings, through: :landing_joint_themes
  has_many :landing_subjects, inverse_of: :landing_theme, dependent: :destroy


  ## Validation
  #
  validates :slug, presence: true, uniqueness: true

  def to_s
    slug
  end

  def to_param
    slug
  end

  # REQUIRED_FIELDS_FLAGS = %i[
  #   requires_full_name
  #   requires_phone_number
  #   requires_email
  #   requires_siret
  #   requires_requested_help_amount
  #   requires_location
  # ]
  # REQUIRED_FIELDS_FLAGS.each do |flag|
  #   scope flag, -> { where(flag => true) }
  #   scope "not_#{flag}", -> { where(flag => false) }
  # end

  # def required_fields
  #   attributes.symbolize_keys
  #     .slice(*REQUIRED_FIELDS_FLAGS)
  #     .filter{ |_, value| value }
  #     .keys
  #     .map{ |flag| flag.to_s.delete_prefix('requires_').to_sym }
  # end
end
