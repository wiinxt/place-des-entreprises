class Commune < ApplicationRecord
  ## Constants
  #
  INSEE_CODE_FORMAT = /\A[0-9AB]{5}\z/

  ## Relations and Validations
  #
  has_and_belongs_to_many :territories
  has_many :facilities
  has_and_belongs_to_many :antennes

  has_many :experts, through: :territories # this is the current state of data and will be `through: :antennes`
  has_and_belongs_to_many :direct_experts, class_name: 'Expert'
  has_many :antenne_experts, through: :antennes, source: :experts
  has_many :relays, through: :territories

  validates :insee_code, presence: true, uniqueness: true, format: { with: INSEE_CODE_FORMAT }

  ##
  #
  def all_experts
    # Direct or through Antennes; returns an ActiveRecord Relation rather than an array.
    Expert.where(id: direct_experts)
      .or(Expert.where(id: antenne_experts).where(id: Expert.without_custom_zone)) # Experts of the antennes on this Commune, who don’t override their Antenne zone.
  end

  ##
  #
  def to_s
    insee_code
  end
end
