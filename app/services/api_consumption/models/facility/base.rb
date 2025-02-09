module ApiConsumption::Models
  class Facility::Base < Base
    def insee_code
      raise 'missing'
    end

    def naf_libelle
      raise 'missing'
    end

    def readable_locality
      [code_postal, libelle_commune].compact_blank.join(' ').presence
    end

    def code_region
      @code_region ||= I18n.t(code_departement, scope: 'department_code_to_region_code')
    end

    def libelle_region
      @libelle_region ||= I18n.t(code_region, scope: 'regions_codes_to_libelles')
    end

    def commune
      @commune ||= Commune.find_or_create_by insee_code: insee_code
    end

    def code_departement
      insee_code.start_with?('97') ? insee_code[0..2] : insee_code[0..1]
    end

    def opco
      @opco ||= Institution.opco.find_by(siren: opcoSiren)
    end
  end
end
