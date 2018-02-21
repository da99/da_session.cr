
require "http"
require "json"
require "random/secure"
require "openssl/hmac"

class DA_Session

  class Invalid_Secret < Exception
  end

  # =============================================================================
  # Instance
  # =============================================================================

  ID_SIZE = 32

  getter id : String? = nil

  getter context     : HTTP::Server::Context
  getter secret      : String
  getter secure      : Bool
  getter lifespan    : Time::Span
  getter cookie_name : String
  getter domain      : String?
  getter path        : String

  def initialize(
    @context,
    @secret      = "",
    @secure      = true,
    @lifespan    = 1.hour,
    @cookie_name = "da_session_id",
    @domain      = nil,
    @path        = "/"
  )
    if secret.size < 10
      raise Invalid_Secret.new("Secret size is too small")
    end
    @is_in_client = false
    @is_deleted   = false
    @is_new       = false
  end

  def id
    @id.not_nil!
  end

  def id?
    (@id || "").size == ID_SIZE
  end

  def new?
    @is_new
  end

  def in_client?
    @is_in_client
  end

  def deleted?
    @is_deleted
  end

  def encoded_id
    encoded_id(@id.not_nil!)
  end # === def encoded_id

  def encoded_id(sess_id : String)
    OpenSSL::HMAC.hexdigest(:sha512, secret, sess_id)
  end

  def load
    cookie_value  = context.request.cookies[cookie_name]?.try(&.value)

    @is_in_client = cookie_value.is_a?(String)
    return false if !in_client?
    return false if !cookie_value.is_a?(String)


    # Is the session valid?
    parts = cookie_value.split(",")
    if !(parts.size == 2)
      delete
      return false
    end

    old_id   = parts[0]
    old_val  = parts[1]
    new_val  = encoded_id(old_id)
    is_valid = (new_val == old_val && old_id.size == ID_SIZE)
    if is_valid
      @id = old_id
    else
      delete
    end

    in_client?
  end

  def save
    if deleted?
      raise Exception.new("Can't save a deleted cookie.") 
    end

    if in_client?
      # It's in the client and not deleted.
      # So it's valid and we are done.
      return true
    end

    _id = @id = Random::Secure.hex

    @context.response.cookies << new_cookie("#{_id},#{encoded_id(_id)}")

    @is_new = true
    new?
  end

  def new_cookie(value : String = "")
    HTTP::Cookie.new(
      name:      cookie_name,
      value:     value,
      expires:   Time.now.to_utc + @lifespan,
      http_only: true,
      secure:    secure,
      path:      path,
      domain:    domain
    )
  end

  def delete
    context.response.cookies << new_cookie("")
    @is_deleted = true
    nil
  end

  # =============================================================================
  # Class
  # =============================================================================

end # === class Session

