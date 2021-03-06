#
# Postfacto, a free, open-source and self-hosted retro tool aimed at helping
# remote teams.
#
# Copyright (C) 2016 - Present Pivotal Software, Inc.
#
# This program is free software: you can redistribute it and/or modify
#
# it under the terms of the GNU Affero General Public License as
#
# published by the Free Software Foundation, either version 3 of the
#
# License, or (at your option) any later version.
#
#
#
# This program is distributed in the hope that it will be useful,
#
# but WITHOUT ANY WARRANTY; without even the implied warranty of
#
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#
# GNU Affero General Public License for more details.
#
#
#
# You should have received a copy of the GNU Affero General Public License
#
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
class ApplicationController < ActionController::Base
  protect_from_forgery
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  protected

  def load_retro
    @retro = Retro.friendly.find(params.fetch(:retro_id))
  end

  def authenticate_retro
    @retro ||= load_retro
    render json: {}, status: :forbidden unless user_allowed_to_access_retro?
  end

  def authenticate_retro_admin
    @retro ||= load_retro
    render json: {}, status: :forbidden unless user_allowed_to_perform_admin_action?
  end

  def user_allowed_to_access_retro?
    return true unless @retro.is_private?

    !@retro.requires_authentication? || valid_token_provided?
  end

  def user_allowed_to_perform_admin_action?
    !@retro.requires_authentication? || valid_token_provided?
  end

  def valid_token_provided?
    authenticate_with_http_token do |token, _options|
      token == @retro.auth_token && !@retro.token_has_expired?(Rails.configuration.session_time, CLOCK.current_time)
    end
  end

  private

  def record_not_found
    render json: {}, status: :not_found
  end
end
