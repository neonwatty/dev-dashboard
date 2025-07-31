module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      set_authentication_required_message
      
      respond_to do |format|
        format.html { redirect_to new_session_path }
        format.turbo_stream { redirect_to new_session_path }
        format.json { render json: { error: "Authentication required" }, status: :unauthorized }
      end
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
    end

    def set_authentication_required_message
      feature_name = get_feature_name_from_request
      session[:auth_required_info] = {
        message: "Authentication required to access #{feature_name}",
        feature: feature_name,
        return_url: request.url
      }
    end

    def get_feature_name_from_request
      case request.path
      when /^\/sources/
        case request.path
        when /\/sources\/new/
          "Source Creation"
        when /\/sources\/\d+\/edit/
          "Source Editing"
        when /\/sources$/
          "Sources Management"
        else
          "Sources"
        end
      when /^\/analysis/
        "Analytics Dashboard"
      when /^\/settings/
        "Account Settings"
      else
        "this feature"
      end
    end
end
