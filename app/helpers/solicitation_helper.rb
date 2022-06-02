module SolicitationHelper
  def solicitation_step_class(index, current_step)
    steps = Solicitation.incompleted_statuses
    current_step_index = steps.index(current_step.to_s)
    if index < current_step_index
      'done'
    elsif index == current_step_index
      'active'
    else
      ''
    end
  end

  ## Google Ads helpers
  # Our ads params are
  # pk_campaign=googleads-{campaignid}
  # pk_kwd={creative}-{keyword}
  def link_to_tracked_campaign(solicitation)
    campaign_components = solicitation.pk_campaign&.split('-', 2)
    if campaign_components.present? && campaign_components.first == 'googleads'
      link_to solicitation.pk_campaign, "https://ads.google.com/aw/adgroups?campaignId=#{campaign_components.last}"
    else
      solicitation.pk_campaign
    end
  end

  def link_to_tracked_ad(solicitation)
    campaign_components = solicitation.pk_campaign&.split('-', 2)
    if campaign_components.present? && campaign_components.first == 'googleads'
      keyword_components = solicitation.pk_kwd.split('-', 2)
      link_to solicitation.pk_kwd, "https://ads.google.com/aw/ads/versions?adId=#{keyword_components.first}"
    else
      solicitation.pk_kwd
    end
  end

  STATUS_ACTION_COLORS = {
    in_progress: %w[yellow],
    processed: %w[grey],
    canceled: %w[red]
  }

  def status_action_link(solicitation, new_status, classes = %w[])
    name = Solicitation.human_attribute_value(:status, new_status, context: :action)
    path = update_status_conseiller_solicitation_path(solicitation, status: new_status)
    classes += STATUS_ACTION_COLORS[new_status.to_sym]
    link_to name, path, method: :post, remote: true, class: classes.join(' ')
  end

  def subject_tag(solicitation, classes = %[])
    landing_subject = solicitation.landing_subject
    if landing_subject.present?
      title_components = {}
      subject = landing_subject.subject
      title_components[t('attributes.subject')] = subject
      title = "#{t('attributes.subject')} : #{subject}"
      path = new_solicitation_path(solicitation.landing.slug, solicitation.landing_subject.slug, siret: params[:siret].presence, anchor: 'section-breadcrumbs')
      link_to landing_subject.title, path, class: classes, title: title
    end
  end

  def link_to_diagnosis(diagnosis)
    if diagnosis.step_completed?
      text = t('helpers.solicitation.view_completed_analysis')
    else
      text = t('helpers.solicitation.analysis_in_progress', step: diagnosis.human_attribute_value(:step))
    end

    link_to text, diagnosis, class: 'ui item'
  end

  def possible_territories_options(territories = Territory.deployed_regions)
    territory_options = territories.map do |territory|
      [territory.name, territory.id]
    end
    territory_options.push(
      [ t('helpers.solicitation.out_of_deployed_territories_label'), t('helpers.solicitation.out_of_deployed_territories_value') ],
      [ t('helpers.solicitation.uncategorisable_label'), t('helpers.solicitation.uncategorisable_value') ]
    )
  end

  def display_region(region, territory_params)
    # display region if there is no region filter
    return unless ((territory_params.present? &&
      (territory_params == 'uncategorisable' || territory_params == 'out_of_deployed_territories')) ||
      territory_params.blank?) && region.present?
    tag.div(class: 'item') do
      t('helpers.solicitation.localisation_html', region: region.name)
    end
  end
end
