# == Schema Information
#
# Table name: facilities
#
#  id                :bigint(8)        not null, primary key
#  code_effectif     :string
#  naf_code          :string
#  naf_libelle       :string
#  readable_locality :string
#  siret             :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  commune_id        :bigint(8)        not null
#  company_id        :bigint(8)        not null
#
# Indexes
#
#  index_facilities_on_commune_id  (commune_id)
#  index_facilities_on_company_id  (company_id)
#  index_facilities_on_siret       (siret) UNIQUE WHERE ((siret)::text <> NULL::text)
#
# Foreign Keys
#
#  fk_rails_...  (commune_id => communes.id)
#  fk_rails_...  (company_id => companies.id)
#

class Facility < ApplicationRecord
  include Effectif

  ## Associations
  #
  belongs_to :company, inverse_of: :facilities
  belongs_to :commune, inverse_of: :facilities

  has_many :diagnoses, inverse_of: :facility

  ## Validations
  #
  validates :company, :commune, presence: true
  validates :siret, uniqueness: { allow_nil: true }

  ## “Through” Associations
  #
  # :diagnoses
  has_many :needs, through: :diagnoses, inverse_of: :facility
  has_many :matches, through: :diagnoses, inverse_of: :facility

  # :commune
  has_many :territories, through: :commune, inverse_of: :facilities

  accepts_nested_attributes_for :company

  ##
  #
  class << self
    def siret_from_query(query)
      maybe_siret = clean_siret(query)
      maybe_siret if siret_is_valid(maybe_siret)
    end

    def clean_siret(maybe_siret)
      maybe_siret&.gsub(/[\W_]+/, '')
    end

    def siret_is_valid(siret)
      siret.present? && siret.match?(/^\d{14}$/) &&
        (luhn_valid(siret) || siret_is_hardcoded_valid(siret))
    end

    def luhn_valid(str)
      s = str.reverse
      sum = 0
      (0..s.size - 1).step(2) do |k| # k is odd, k+1 is even
        sum += s[k].to_i # s1
        tmp = s[k + 1].to_i * 2
        if tmp > 9
          tmp = tmp.to_s.split(//).sum(&:to_i)
        end
        sum += tmp
      end
      (sum % 10).zero?
    end

    def siret_is_hardcoded_valid(siret)
      # https://fr.wikipedia.org/wiki/Système_d%27identification_du_répertoire_des_établissements
      # Pour des raisons historiques, les SIRET attribués aux établissements du groupe La Poste utilisent une autre formule de validation, et ne sont donc pas tous valides au sens de la formule de Luhn. Le groupe La Poste ayant le SIREN : 356000000, les SIRET suivant cette autre formule de validation sont de la forme 356000000XXXXX
      siret.match?(/356000000...../)
    end
  end

  ## insee_code / commune helpers
  # TODO: insee_code should be just a column in facility, and we should drop the Commune model entirely.
  #   In the meantime, fake it by delegating to commune.
  delegate :insee_code, to: :commune, allow_nil: true # commune can be nil in new facility models.
  def insee_code=(insee_code)
    self.commune = Commune.find_or_initialize_by(insee_code: insee_code)
    city_params = ApiAdresse::Query.city_with_code(insee_code)
    self.readable_locality = "#{city_params['codesPostaux']&.first} #{city_params['nom']}"
  end

  def commune_name
    readable_locality || insee_code
  end

  ##
  #
  def to_s
    "#{company.name} (#{commune_name})"
  end
end
