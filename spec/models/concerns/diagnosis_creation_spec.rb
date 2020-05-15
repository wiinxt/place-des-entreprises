# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DiagnosisCreation do
  describe 'new_diagnosis' do
    context 'with a solicitation' do
      subject(:diagnosis){ described_class.new_diagnosis(solicitation) }

      let(:solicitation) { build :solicitation, full_name: 'my company' }

      it do
        expect(diagnosis.facility.company.name).to eq 'my company'
      end
    end
  end

  describe 'create_diagnosis' do
    # the subject has to be called as a block (expect{create_diagnosis}) for raise matchers to work correctly.
    subject(:create_diagnosis) { described_class.create_diagnosis(params) }

    let(:advisor) { create :user }
    let(:params) { { advisor: advisor, facility_attributes: facility_params } }

    context 'with invalid facility data' do
      let(:facility_params) { { invalid: 'value' } }

      it do
        expect{ create_diagnosis }.to raise_error ActiveModel::UnknownAttributeError
      end
    end

    context 'with a facility siret' do
      let(:siret) { '12345678901234' }
      let(:facility_params) { { siret: siret } }

      context 'when the siret is valid' do
        before do
          allow(UseCases::SearchFacility).to receive(:with_siret_and_save).with(siret) { create(:facility, siret: siret) }
        end

        it 'fetches info for ApiEntreprise and creates the diagnosis' do
          expect{ create_diagnosis }.not_to raise_error
          expect(create_diagnosis).to be_valid
        end
      end

      context 'when the siret is unknown' do
        before do
          allow(UseCases::SearchFacility).to receive(:with_siret_and_save).with(siret) { raise ApiEntreprise::ApiEntrepriseError, 'some error message' }
        end

        it 'fetches info for ApiEntreprise and creates the diagnosis' do
          expect{ create_diagnosis }.to raise_error ApiEntreprise::ApiEntrepriseError
        end
      end
    end

    context 'with manual facility info' do
      let(:insee_code) { '78586' }
      let(:facility_params) { { insee_code: insee_code, company_attributes: { name: 'Boucherie Sanzot' } } }

      before do
        city_json = JSON.parse(file_fixture('geo_api_communes_78586.json').read)
        allow(ApiAdresse::Query).to receive(:city_with_code).with(insee_code) { city_json }
      end

      it 'creates a new diagnosis without siret' do
        expect{ create_diagnosis }.not_to raise_error
        expect(create_diagnosis).to be_valid
        expect(create_diagnosis.company.name).to eq 'Boucherie Sanzot'
      end
    end
  end

  describe 'prepare_needs_from_solicitation' do
    let(:diagnosis) { create :diagnosis, solicitation: solicitation }
    let(:solicitation) { create :solicitation }

    before do
      allow(solicitation).to receive(:preselected_subjects).and_return(subjects)
      diagnosis.prepare_needs_from_solicitation
    end

    context 'solicitation has preselected subjects' do
      let(:subjects) { create_list :subject, 2 }

      it 'creates needs' do
        expect(diagnosis.needs.count).to eq 2
      end
    end

    context 'solicitation has no preselected subjects' do
      let(:subjects) { [] }

      it 'sets an error' do
        expect(diagnosis.needs).to be_empty
        expect(diagnosis.errors.details).to eq({ needs: [{ error: :solicitation_has_no_preselected_subjects }] })
      end
    end
  end

  describe 'prepare_visitee_from_solicitation' do
    let(:diagnosis) { create :diagnosis, solicitation: solicitation, visitee: nil }

    before do
      diagnosis.prepare_visitee_from_solicitation
    end

    context 'solicitation has all details' do
      let(:solicitation) { create :solicitation }

      it 'creates the visitee' do
        expect(diagnosis.visitee).to be_persisted
      end
    end

    context 'solicitation is missing some details' do
      let(:solicitation) { build :solicitation, full_name: nil }

      it 'sets an error' do
        expect(diagnosis.visitee).not_to be_persisted
        expect(diagnosis.errors.details).to eq({ :"visitee.full_name" => [{ error: :blank }] })
      end
    end
  end
end
