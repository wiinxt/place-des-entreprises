class CreateLandingSubjects < ActiveRecord::Migration[6.1]
  def change
    create_table :landing_themes do |t|
      t.string :title
      t.string :page_title
      t.string :slug
      t.text :description
      t.string :meta_title
      t.string :meta_description
      t.string :logos
      t.string :main_logo
      t.timestamps null: false
    end

    create_table :landing_subjects do |t|
      t.references :landing_theme, null: false, foreign_key: true
      t.references :subject, null: false, foreign_key: true
      t.string :title
      t.string :slug
      t.text :description
      t.integer :position
      t.string :meta_title
      t.string :meta_description
      t.string :form_title
      t.text :form_description
      t.text :description_explanation
      t.boolean :requires_siret, default: false, null: false
      t.boolean :requires_requested_help_amount, default: false, null: false
      t.boolean :requires_location, default: false, null: false

      t.timestamps null: false
    end

    create_table :landing_joint_themes do |t|
      t.references :landing
      t.references :landing_theme
      t.integer :position
      t.timestamps null: false
    end

    add_index :landing_themes, :slug, unique: true
    # TODO remettre en unique
    add_index :landing_subjects, [:slug, :landing_theme_id], :unique => true

    add_column :landings, :layout, :integer, default: 1
    add_column :landings, :iframe, :boolean, default: false
    change_column_null :solicitations, :landing_slug, true

    add_reference :solicitations, :landing, foreign_key: true, null: true
    add_reference :solicitations, :landing_subject, foreign_key: true, null: true

    # Utilisé uniquement sur "relance"
    # - emphasis
    # - main_logo

    up_only do
      def defaults_landing_theme_attributes(landing)
        {
          title: landing.home_title,
          page_title: landing.title,
          slug: landing.slug,
          description: landing.home_description || landing.meta_description,
          meta_title: landing.meta_title,
          meta_description: landing.meta_description,
          logos: landing.logos,
          main_logo: landing.main_logo
        }
      end

      def defaults_landing_subject_attributes(landing_theme, landing_topic)
        landing_option = LandingOption.find_by(slug: landing_topic.landing_option_slug)
        subject = Subject.find_by(slug: landing_option.preselected_subject_slug)
        {
          landing_theme_id: landing_theme.id,
          subject_id: subject.id,
          title: landing_topic.title,
          slug: landing_topic.landing_option_slug.dasherize.parameterize,
          description: landing_topic.description,
          meta_title: landing_option.meta_title,
          meta_description: nil,
          form_title: landing_option.form_title,
          form_description: landing_option.form_description,
          description_explanation: landing_option.description_explanation,
          requires_siret: landing_option.requires_siret,
          requires_requested_help_amount: landing_option.requires_requested_help_amount,
          requires_location: landing_option.requires_location
        }
      end

      ## Home Landing
      home_landing = Landing.where(slug: 'accueil').first_or_create(
        title: 'Accueil'
      )

      # Themes de la page d'accueil
      Landing.where.not(home_sort_order: nil).order(:home_sort_order).each do |landing|
        landing_theme_attributes = defaults_landing_theme_attributes(landing)
        landing_theme = home_landing.landing_themes.create(landing_theme_attributes)

        landing.landing_topics.order(:landing_sort_order).each do |lt|
          ls_attributes = defaults_landing_subject_attributes(landing_theme, lt)
          LandingSubject.create(ls_attributes)
        end

        landing.solicitations.each do |sol|
          landing_option = sol.landing_option
          if landing_option.present?
            landing_subject = retrieve_landing_subject(landing_option) || landing_theme.landing_subjects.first
          else
            landing_subject = landing_theme.landing_subjects.first
          end

          sol.update(
            landing_id: home_landing.id,
            landing_slug: home_landing.slug,
            landing_subject_id: landing_subject&.id || nil
          )
        end
      end

      # Landing avec des group_name
      Landing.where(slug: ['relance', 'brexit', 'relance-hautsdefrance']).each do |landing|
        landing.update(layout: :single_page)
        if landing.slug == 'brexit'
          landing.custom_css << "\n.landing-cards-container .card { background: none !important; box-shadow: none !important; }"
          landing.save!
        end
        # Create themes for each group_name
        landing.landing_topics.order(:landing_sort_order).pluck(:group_name).compact.each do |group_name|
          theme_slug = group_name.parameterize
          lt = LandingTheme.find_by(slug: theme_slug)
          if lt.present?
            landing.landing_themes << lt unless landing.landing_themes.include?(lt)
          else
            landing_theme_attributes = defaults_landing_theme_attributes(landing).merge(
              title: group_name,
              slug: theme_slug,
            )
            landing.landing_themes.create(landing_theme_attributes)
          end
        end
        landing.landing_topics.order(:landing_sort_order).each do |lt|
          landing_theme = LandingTheme.find_by(title: lt.group_name)
          ls_attributes = defaults_landing_subject_attributes(landing_theme, lt)
          LandingSubject.create(ls_attributes)
        end
      end

      ## Landing "contactez-nous"
      Landing.where(slug: ['contactez-nous']).each do |landing|
        landing.update(layout: :single_page)
        landing_theme_attributes = defaults_landing_theme_attributes(landing).merge(
          title: 'Échanger avec un conseiller pour :',
        )
        landing_theme = landing.landing_themes.create(landing_theme_attributes)
        landing.landing_topics.order(:landing_sort_order).each do |lt|
          ls_attributes = defaults_landing_subject_attributes(landing_theme, lt)
          LandingSubject.create(ls_attributes)
        end
      end

      # Iframes
      ## Iframe 360°
      [
        {
          slug: 'zetwal', title: 'Zetwal', institution_id: 146, partner_url: 'https://www.zetwal.mq/deposer-une-demande-2/', iframe: true, custom_css:  "section.section, section.section-grey, .section-grey, #section-thankyou {
          background-color: #ECF3FC !important; }.card, .landing-topic.block-link {  background-color: #ffffff !important;}.landing-topic.block-link {  margin-right: 2rem !important;  flex: 0 0 45% !important;  padding: 20px !important}"
        },
        { slug: 'entreprises-haut-de-france', title: 'Entreprises Haut de France', institution_id: 31, partner_url: 'https://entreprises.hautsdefrance.fr/Contact', iframe: true, custom_css: '' }
      ].each do |hash|
        landing = Landing.where(slug: hash[:slug]).first_or_create(
          title: hash[:title],
          institution_id: hash[:institution_id],
          partner_url: hash[:partner_url],
          iframe: hash[:iframe],
          custom_css: hash[:custom_css],
        )
        landing.landing_themes << home_landing.landing_themes
      end
      ## France transition ecologique
      Landing.where(slug: ['france-transition-ecologique']).each do |landing|
        landing.update(layout: :single_page, iframe: true)
        ecolo_theme = LandingTheme.find_by(slug: "environnement-transition-ecologique")
        landing.landing_themes << ecolo_theme
      end

      Landing.where(slug: ['brexit', 'relance-hautsdefrance']).each { |l| l.update(iframe: true) }

      ## MaJ solicitations restantes
      Solicitation.where(landing_subject: nil).each do |sol|
        landing = Landing.find_by(slug: sol.landing_slug)
        landing_option = sol.landing_option
        if landing_option.present?
          landing_subject = retrieve_landing_subject(landing_option)
        end

        sol.update(
          landing_id: landing&.id,
          landing_subject_id: landing_subject&.id || nil
        )
      end
      ## On supprime les landing qui ne servent plus
      Landing.where.not(home_sort_order: nil).destroy_all
    end
  end

  def retrieve_landing_subject(landing_option)
    subject = Subject.find_by(slug: landing_option.preselected_subject_slug)
    LandingSubject.find_by(subject_id: subject.id)
  end
end

# LandingOption.find_by(slug: "energie").update(preselected_subject_slug: "environnement_transition_ecologique_rse_gestion_de_l_energie")
# LandingOption.find_by(slug: "dechets").update(preselected_subject_slug: "environnement_transition_ecologique_rse_traitement_et_valorisation_des_dechets")
# LandingOption.find_by(slug: "eau").update(preselected_subject_slug: "environnement_transition_ecologique_rse_gestion_de_l_eau")
# LandingOption.find_by(slug: "bilan_RSE").update(preselected_subject_slug: "environnement_transition_ecologique_rse_bilan_et_strategie_rse")
# LandingOption.find_by(slug: "transport_mobilite").update(preselected_subject_slug: "environnement_transition_ecologique_rse_transport_et_mobilite")
# LandingOption.find_by(slug: "demarche_ecologie").update(preselected_subject_slug: "environnement_transition_ecologique_rse_demarche_generale_de_transition_ecologique_strategie_eco_conception_labels")

# LandingTopic.where(title: "").destroy_all

# LandingOption.find_by(slug: 'obligations_sante_securite').update(preselected_subject_slug: "sante_et_securite_au_travail_repondre_a_mes_obligations_en_matiere_de_sante_et_de_securite")
# LandingOption.find_by(slug: 'former_risques_professionnels').update(preselected_subject_slug: "sante_et_securite_au_travail_former_ses_salaries_a_la_prevention_des_risques_professionnels")
# LandingOption.find_by(slug: 'qualite_de_vie_au_travail').update(preselected_subject_slug: "sante_et_securite_au_travail_ameliorer_la_qualite_de_vie_au_travail_management_teletravail")
