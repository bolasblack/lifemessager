# coding: utf-8

class ApplicationController < ActionController::Base
  SUPPORT_FORMAT = [:json, :xml]

  skip_before_action :verify_authenticity_token
  before_action :default_format # 这个 filter 必须放在最前面，因为它约束了响应的数据格式
  before_action :verify_token
  before_action :verify_timezone_header

  private

  def default_format
    unless SUPPORT_FORMAT.include? request.format
      request.format = SUPPORT_FORMAT.first
    end
  end

  def verify_token
    if authorization.nil?
      error_info = build_error 'Header Authentication is required'
    elsif current_user.nil?
      error_info = build_error 'Header Authentication is invalid'
    end
    return simple_respond(error_info, status: :unauthorized) if error_info
  end

  def verify_timezone_header
    error_info = build_error 'Header Timezone is required'
    return simple_respond(error_info, status: :precondition_required) unless current_timezone
  end

  def current_timezone
    return unless timezone_header = request.headers['Timezone']
    client_time, posixtz, timezone = timezone_header.split ';', 3
    return unless timezone and User.timezones.include? timezone
    timezone
  end

  def current_user
    return unless authorization
    return unless authorization[:type] == 'Bearer'
    token = Token.decode authorization[:token]
    return unless token[:success]
    token[:token].user
  end

  def authorization
    auth = request.authorization || params[:token]
    return unless auth
    auth_parts = auth.split ' ', 2
    {type: auth_parts.first, token: auth_parts.last}
  end

  def simple_respond(resp, opts)
    default_resps = {
      not_found: build_error('Resource not found')
    }

    if default_resp = default_resps[opts[:status]]
      resp = default_resp.merge resp || {}
    end
    format_opt = resp ? {request.format.to_sym => resp} : {nothing: true}
    render format_opt.merge opts
  end

  def build_error message, *args
    {message: message, errors: args.first || []}
  end
end
