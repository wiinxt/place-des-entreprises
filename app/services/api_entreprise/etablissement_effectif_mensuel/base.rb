# frozen_string_literal: true

module ApiEntreprise::EtablissementEffectifMensuel
  class Base < ApiEntreprise::Base
    def request
      Request.new(@siren_or_siret, @options)
    end

    def responder(http_request)
      Responder.new(http_request)
    end

    # Retourne hash vide en cas d'erreur
    def handle_error(http_request)
      return { "effectifs" => { "error" => http_request.error_message } }
    end
  end

  class Request < ApiEntreprise::Request
    def error_message
      @error&.message || @data['error'] || @http_response.status.reason || DEFAULT_ERROR_MESSAGE
    end

    private

    def version
      'v2'
    end

    def url_key
      @url_key ||= 'effectifs_mensuels_acoss_covid/'
    end

    # effectifs_mensuels_acoss_covid/Année/Mois/etablissement/SiretDeL’entreprise
    def specific_url
      @specific_url ||= "#{url_key}#{search_year}/#{search_month}/etablissement/#{@siren_or_siret}"
    end

    def searched_date
      @searched_date ||= Time.zone.now.months_ago(6)
    end

    # il faut un mois avec "0" (08, 09, 10...)
    def search_month
      searched_date.strftime("%m")
    end

    def search_year
      searched_date.year
    end
  end

  class Responder < ApiEntreprise::Responder
    def format_data
      { "effectifs" => @http_request.data.slice('annee', 'mois', 'effectifs_mensuels') }
    end
  end
end
