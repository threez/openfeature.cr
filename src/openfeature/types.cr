module OpenFeature
  alias Int = Int8 | Int16 | Int32 | Int64

  alias Float = Float32 | Float64

  # A numeric value of unspecified type or size. Implementation
  # languages may further differentiate between integers, floating
  # point numbers, and other specific numeric types and provide
  # functionality as idioms dictate.
  alias Number = Int | Float

  # A language primitive for representing a date and time, optionally
  # including timezone information. If no timezone is specified, the date
  # and time will be treated as UTC.
  alias Datetime = Time

  alias CustomField = Bool | String | Number | Datetime

  alias CustomFields = Hash(String, CustomField)

  alias FlagMetadata = Hash(String, Object)

  enum Type
    # A logical true or false, as represented idiomatically in
    # the implementation languages.
    Boolean
    # A UTF-8 encoded string.
    String
    # A numeric value of unspecified type or size. Implementation
    # languages may further differentiate between integers, floating
    # point numbers, and other specific numeric types and provide
    # functionality as idioms dictate.
    Number
    # Structured data, presented however is idiomatic in the
    # implementation language, such as JSON or YAML.
    Structure
    # A language primitive for representing a date and time, optionally
    # including timezone information. If no timezone is specified, the
    # date and time will be treated as UTC.
    Datetime
  end

  # An identifier which logically binds clients with providers, allowing
  # for multiple providers to be used simultaneously within a single
  # application. Domain binding is dynamic; it may change over the course
  # of an application's lifetime (ie: a client associated to the default
  # provider via an unbound domain will be bound to a new provider if a
  # provider is subsequently assigned to that domain).
  alias Domain = String

  # A string that logically identifies a particular flag.
  alias FlagKey = String

  # A variant is a semantic identifier for a value. This allows for referral
  # to particular values without necessarily including the value itself,
  # which may be quite prohibitively large or otherwise unsuitable in some cases.
  alias Variant = String

  # A string logically identifying the subject of evaluation (end-user, service, etc).
  alias TargetingKey = String
end
