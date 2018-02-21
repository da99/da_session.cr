
require "http"
require "json"
require "random/secure"
require "openssl/hmac"

class DA_Session

  # =============================================================================
  # Instance
  # =============================================================================

  ID_SIZE = 32

  getter id : String? = nil

  def initialize(
    @context     : HTTP::Server::Context,
    @lifespan    : Time::Span = 1.hour,
    @cookie_name : String     = "da_session_id",
    @secret      : String     = "",
    @secure      : Bool       = false,
    @doman       : String?    = nil,
    @path        : String     = "/"
  )
    @is_in_client = false
    @is_deleted = false
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

  def encoded_id(sess_id : String)
    OpenSSL::HMAC.hexdigest(:sha512, secret, sess_id)
  end

  def load
    cookie_value  = context.request.cookies[cookie_name]?.try(&.value)
    @is_in_client = cookie_value.is_a?(String)
    return false if !in_client?

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

    @context.response.cookies << HTTP::Cookie.new(
      name:      config.cookie_name,
      value:     "#{_id},#{encoded_id(_id)}",
      expires:   Time.now.to_utc + @lifespan,
      http_only: true,
      secure:    @secure,
      path:      @path,
      domain:    @domain
    )

    @is_new = true
    true
  end

  def delete
    context.response.cookies[cookie_name].value = ""
    @is_deleted = true
    nil
  end

  # =============================================================================
  # Class
  # =============================================================================

end # === class Session

