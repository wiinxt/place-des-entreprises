# frozen_string_literal: true

ActiveAdmin.register Solicitation do
  include CsvExportable

  menu priority: 7

  ## Index
  #
  scope :step_complete, default: true
  scope :step_incomplete

  scope :status_step_company, group: :completion_incomplete
  scope :status_step_description, group: :completion_incomplete

  includes :diagnosis, :landing, :institution, :badges, :landing_subject, needs: :subject, diagnosis: :company

  index do
    selectable_column
    column :solicitation do |s|
      div link_to I18n.t('active_admin.solicitations.id', id: s.id), conseiller_solicitation_path(s)
      div l(s.created_at, format: :admin)
      human_attribute_status_tag s, :status
      div link_to I18n.t('active_admin.admin_link', id: s.id), admin_solicitation_path(s)
    end
    column :description do |s|
      div(admin_link_to(s.landing) || s.landing_slug)
      subject_slug = s.landing_subject&.slug
      if subject_slug.present?
        div t('activerecord.attributes.solicitation.landing_subject') + ' : ' do
          div status_tag subject_slug
        end
      end
      blockquote simple_format(s.description&.truncate(20000, separator: ' '))

      ul class: 'mb-1' do
        s.institution_filters.each do |filter|
          answer = I18n.t(
            filter.filter_value, scope: [:activerecord, :attributes, :additional_subject_questions, filter.key],
            default: I18n.t(filter.filter_value, scope: [:boolean, :text])
          )
          li "- #{I18n.t(:label, scope: [:activerecord, :attributes, :additional_subject_questions, filter.key])} #{tag.strong(answer)} <br>".html_safe
        end
      end
      div raw diagnosis_link(s.diagnosis)
      div raw needs_links(s.needs) if s.needs.present? && s.diagnosis.step_completed?
    end
    column I18n.t('attributes.badges.other') do |s|
      render 'badges', badges: s.badges
    end
    column "#{t('attributes.coordinates')} | #{t('activerecord.attributes.solicitation.tracking')}" do |s|
      div do
        if s.siret.present?
          link_to s.siret, show_with_siret_companies_path(s.siret), data: { turbo: false }
        else
          t('active_admin.solicitations.no_siret')
        end
      end
      div s.full_name
      div s.normalized_phone_number
      div mail_to(s.email)
      hr
      div admin_attr(s, :requested_help_amount) if s.requested_help_amount.present?
      div admin_attr(s, :location) if s.location.present?
      hr
      if s.campaign.present?
        div "#{t('activerecord.attributes.solicitation.mtm_campaign')} : #{link_to_tracked_campaign(s)}".html_safe
      end
      if s.provenance_detail.present?
        div "#{t('activerecord.attributes.solicitation.mtm_kwd')} : « #{link_to_tracked_ad(s)} »".html_safe
      end
      if s.from_relaunch?
        div "#{t('activerecord.attributes.solicitation.relaunch')} : #{s.relaunch}"
      end
      if s.institution.present?
        admin_attr(s, :institution)
      end
    end
  end

  before_action :only => :index do
    @landing_themes = if params[:q].present? && params[:q][:landing_id_eq].present?
      Landing.find(params[:q][:landing_id_eq]).landing_themes
    else
      LandingTheme.all
    end
    @landing_subjects = if params[:q].present? && params[:q][:landing_subject_landing_theme_id_eq].present?
      LandingTheme.find(params[:q][:landing_subject_landing_theme_id_eq]).landing_subjects
    else
      LandingSubject.all
    end
  end

  ## Filters
  #
  preserve_default_filters!
  remove_filter :diagnosis  # ActiveAdmin default filters build selects for all the declared model relations.
  remove_filter :matches    # Displaying them can become very expensive, especially if to_s is implemented
  remove_filter :needs      # and uses yet another relation.
  remove_filter :feedbacks
  remove_filter :updated_at
  remove_filter :institution
  remove_filter :created_in_deployed_region
  remove_filter :badge_badgeables
  remove_filter :institution_filters
  filter :landing, as: :select, collection: -> { Landing.order(:slug).pluck(:slug, :id) }
  filter :landing_theme, as: :select, collection: -> { @landing_themes.order(:title).pluck(:title, :id) }
  filter :landing_subject, as: :select, collection: -> { @landing_subjects.order(:title).pluck(:title, :id) }
  filter :status, as: :select, collection: -> { Solicitation.human_attribute_values(:status, raw_values: true).invert.to_a }
  filter :completion, as: :select, collection: -> { ['step_complete', 'step_incomplete'].map{ |completion| [I18n.t("active_admin.scopes.#{completion}"), completion] } }
  filter :code_region, as: :select, collection: -> { Territory.deployed_regions.order(:name).pluck(:name, :code_region) }
  filter :facility, as: :ajax_select, data: { url: :admin_facilities_path, search_fields: [:name] }
  filter :mtm_campaign, as: :string
  filter :mtm_kwd, as: :string
  filter :relaunch, as: :string
  filter :created_at
  filter :completed_at

  controller do
    before_action only: :index do
      # Mettre filtre solicitation complète par défaut, pour faciliter export
      if params[:commit].blank? && params[:q].blank?
        extra_params = { q: { completion_eq: "step_complete" } }
        params.merge! extra_params
      end
    end
  end

  ## Batch actions
  # Statuses
  Solicitation.statuses.each_key do |status|
    batch_action Solicitation.human_attribute_value(:status, status, context: :action, disable_cast: true) do |ids|
      solicitations = batch_action_collection.where(id: ids)
      solicitations.update(status: status)
      model = Solicitation.model_name.human(count: solicitations.size)
      done = Solicitation.human_attribute_value(:status, status, context: :done, count: solicitations.size)
      redirect_back fallback_location: collection_path, notice: "#{model} #{done}"
    end
  end

  ## CSV
  #
  csv do
    column :id
    column :created_at
    column :status
    column :description
    column :siret
    column :full_name
    column :phone_number
    column :email
    column(:provenance_category) { |s| I18n.t(s.provenance_category, scope: %i(solicitation provenance_categories)) }
    column(:landing) { |s| s.landing&.slug }
    column(:subject) { |s| s.landing_subject&.slug }
    column :diagnosis
    column(:badges) { |s| s.badges.map(&:to_s).join(",") }
    column(:regions) { |s| s.region&.name }
    Solicitation::FORM_INFO_KEYS.each { |k| column k, humanize_name: false }
  end

  ## Show
  #
  show title: :to_s do
    panel I18n.t('attributes.description') do
      div(admin_link_to(solicitation.landing) || solicitation.landing_slug)
      blockquote simple_format(solicitation.description)
    end

    attributes_table title: t('attributes.coordinates') do
      row :siret do |s|
        if s.siret.present?
          div link_to s.siret, show_with_siret_companies_path(s.siret), data: { turbo: false }
        end
      end
      row :full_name
      row :phone_number
      row :email
      row(:code_region) do |i|
        I18n.t(i.code_region, scope: 'regions_codes_to_libelles', default: "")
      end
    end

    attributes_table title: t('activerecord.attributes.solicitation.tracking') do
      row I18n.t('attributes.badges.other') do |s|
        render 'badges', badges: s.badges
      end
      row :tracking do |s|
        render 'conseiller/solicitations/tracking', solicitation: s
      end
      row :institution
    end
  end

  sidebar I18n.t('activerecord.models.solicitation.one'), only: :show do
    attributes_table_for solicitation do
      row(:status) { human_attribute_status_tag solicitation, :status }
      row :diagnosis
      row :created_at
      row :completed_at
      row :updated_at
    end
  end

  ## Form
  #
  permit_params :description, :status, :siret, :full_name, :phone_number, :email, badge_ids: []
  form do |f|
    f.inputs do
      f.input :status, as: :select, collection: Solicitation.human_attribute_values(:status).invert.to_a
      f.input :email
      f.input :full_name
      f.input :phone_number
      f.input :siret
      f.input :location
      f.input :description, as: :text
      f.input :badges, collection: Badge.all
    end

    f.actions
  end

  form_options = -> do
    { action: %w[ajouter enlever], badge: Badge.all.map { |b| [b.title, b.id] } }
  end
  batch_action I18n.t('active_admin.badges.add_remove'), form: form_options do |ids, inputs|
    badge = Badge.find(inputs[:badge])
    case inputs[:action]
    when 'ajouter'
      Solicitation.where(id: ids).each { |s| s.badges << badge }
    when 'enlever'
      Solicitation.where(id: ids).each { |s| s.badges.delete(badge) }
    end
    redirect_to collection_path, notice: I18n.t('active_admin.badges.modified', action: inputs[:action].gsub('er', 'é'))
  end
end
