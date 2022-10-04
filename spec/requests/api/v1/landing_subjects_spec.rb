require "rails_helper"
require 'swagger_helper'

RSpec.describe "Landing Subjects API", type: :request do
  let(:institution) { create(:institution) }
  let(:Authorization) { "Bearer token=#{find_token(institution)}" }
  let(:landing_01) { create_base_landing(institution) }
  let!(:rh_theme) { create_rh_theme([landing_01]) }
  let!(:recrutement_subject) { create_recrutement_subject(rh_theme) }
  let!(:formation_subject) { create_formation_subject(rh_theme) }
  let!(:cadre_question) { create_cadre_question(recrutement_subject.subject) }
  let!(:apprentissage_question) { create_apprentissage_question(recrutement_subject.subject) }

  # Génération automatique des exemples dans la doc
  after do |example|
    content = example.metadata[:response][:content] || {}
    example_spec = {
      "application/json" => {
        examples: {
          test_example: {
            value: JSON.parse(response.body, symbolize_names: true)
          }
        }
      }
    }
    example.metadata[:response][:content] = content.deep_merge(example_spec)
  end

  describe 'index' do
    path '/api/v1/landing_subjects' do
      get 'Liste des sujets' do
        tags 'Sujets'
        description 'Affiche tous les sujets pour l’organisation authentifiée'
        produces 'application/json'

        response '200', 'ok' do
          schema type: :object,
                 properties: {
                   data: {
                     type: :array,
                     items: {
                       '$ref': "#/components/schemas/landing_subject"
                     }
                   },
                   metadata: {
                     type: :object,
                     properties: {
                       total_results: {
                         type: :integer,
                         description: 'Nombre de sujets pour l’organisation authentifiée.'
                       }
                     }
                   }
                 }

          let(:landing_02) { create(:landing, :api, institution: institution, title: 'Page d’atterrissage 02', slug: 'page-atterrissage-02') }
          let!(:sante_theme) { create_sante_theme([landing_02]) }
          let!(:sante_sujet) { create_obligations_sante_subject(sante_theme) }

          before do |example|
            submit_request(example.metadata)
          end

          it 'returns a valid 200 response' do |example|
            expect(response).to have_http_status(:ok)
            result = JSON.parse(response.body)
            expect(result.size).to eq(2)
            expect(result['data'].size).to eq(3)
          end
        end
      end
    end
  end

  describe 'show' do
    path '/api/v1/landing_subjects/{id}' do
      get 'Page sujet' do
        tags 'Sujets'
        description 'Affiche le détail d’un formulaire sujet'
        parameter name: :id, in: :path, type: :string, description: 'identifiant du sujet', required: true
        produces 'application/json'

        response '200', 'Sujet trouvée' do
          schema type: :object,
                 properties: {
                   data: {
                     '$ref' => '#/components/schemas/landing_subject'
                   },
                   metadata: {
                     type: :object
                   }
                 }

          let(:id) { recrutement_subject.id }

          before do |example|
            submit_request(example.metadata)
          end

          it 'returns a valid 200 response' do |example|
            expect(response).to have_http_status(:ok)
            result = JSON.parse(response.body)
            expect(result.size).to eq(1)

            result_item = result['data']
            expect(result_item.keys).to match_array(["id", "title", "slug", "landing_id", "landing_theme_id", "landing_theme_slug", "description", "description_explanation", "requires_siret", "requires_location", "questions_additionnelles"])
            expect(result_item["title"]).to eq('Recruter un ou plusieurs salariés')
            expect(result_item["landing_theme_slug"]).to eq('recrutement-formation')
          end
        end
      end
    end
  end
end
