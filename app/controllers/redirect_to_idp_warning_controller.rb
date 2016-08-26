class RedirectToIdpWarningController < ApplicationController
  SELECTED_IDP_HISTORY_LENGTH = 5
  helper_method :user_has_no_docs_or_foreign_id_only?, :other_ways_description

  def index
    @idp = decorated_idp
    if @idp.viewable?
      @recommended = recommended?
      render 'index'
    else
      something_went_wrong("Couldn't display IDP with entity id: #{@idp.entity_id}")
    end
  end

  def continue
    idp = decorated_idp
    if idp.viewable?
      select_registration(idp)
      redirect_to redirect_to_idp_path
    else
      something_went_wrong("Couldn't display IDP with entity id: #{idp.entity_id}")
    end
  end

  def continue_ajax
    idp = decorated_idp
    if idp.viewable?
      select_registration(idp)
      outbound_saml_message = journey.idp_authn_request
      idp_request = IdentityProviderRequest.new(
        outbound_saml_message,
        idp.simple_id,
        selected_answer_store.selected_answers)
      render json: idp_request.to_json(methods: :hints)
    else
      render status: :bad_request
    end
  end

private

  def select_registration(idp)
    journey.confirm_registration(idp)
    set_journey_hint(idp.entity_id)
    register_idp_selections(idp.display_name)
  end

  def register_idp_selections(idp_name)
    selected_idp_names = session[:selected_idp_names] || []
    if selected_idp_names.size < SELECTED_IDP_HISTORY_LENGTH
      selected_idp_names << idp_name
      session[:selected_idp_names] = selected_idp_names
    end
    FEDERATION_REPORTER.report_idp_registration(request, idp_name, selected_idp_names, selected_answer_store.selected_evidence, recommended?, flash[:selected_idp_index], flash[:idp_count])
  end

  def recommended?
    session.fetch(:selected_idp_was_recommended)
  end

  def decorated_idp
    @decorated_idp ||= IDENTITY_PROVIDER_DISPLAY_DECORATOR.decorate(journey.selected_idp)
  end

  def other_ways_description
    @other_ways_description = journey.transaction.other_ways_description
  end

  def user_has_no_docs_or_foreign_id_only?
    user_has_no_docs? || user_has_foreign_doc_only?
  end

  def user_has_no_docs?
    selected_answer_store.selected_evidence_for('documents').empty?
  end

  def user_has_foreign_doc_only?
    selected_answer_store.selected_evidence_for('documents') == [:non_uk_id_document]
  end
end
