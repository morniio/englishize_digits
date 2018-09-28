# frozen_string_literal: true

require "englishize_digits/version"
require "active_model"

module ActiveModel::Validations::HelperMethods
  # Convert non-English digits from model fields to English.
  def englishize_digits(options = nil)
    EnglishizeDigits.validate_options(options) unless options.nil? || options.keys.empty?

    before_validation do |record|
      EnglishizeDigits.convert(record, options)
    end
  end
end

module EnglishizeDigits
  VALID_OPTIONS = %i[only except].freeze
  EN_DIGITS = "0123456789"

  AR_DIGITS = "٠١٢٣٤٥٦٧٨٩"
  HI_DIGITS = "०१२३४५६७८९"
  UR_DIGITS = "۰۱۲۳۴۵۶۷۸۹"
  AVAILABLE_LANGUAGES = [AR_DIGITS, HI_DIGITS, UR_DIGITS].freeze

  def self.convert(record_or_attribute, options = nil)
    if record_or_attribute.respond_to?(:attributes)
      convert_record(record_or_attribute, options)
    elsif record_or_attribute.is_a?(String)
      convert_string(record_or_attribute)
    else
      record_or_attribute
    end
  end

  def self.convert_record(record, options = nil)
    attributes = narrow(record.attributes, options)

    attributes.each do |attr, value|
      if value.is_a?(String) && !attr.include?("password")
        record[attr] = convert_string(value)
      end
    end

    record
  end

  def self.convert_string(value)
    AVAILABLE_LANGUAGES.each { |lang| value = value.try(:tr, lang, EN_DIGITS) }

    value
  end

  # Necessary because Rails has removed the narrowing of attributes using :only
  # and :except on Base#attributes
  def self.narrow(attributes, options = {})
    return attributes if options.blank?

    if options[:except]
      except = options[:except]
      except = Array(except).map(&:to_s)
      attributes.except(*except)

    elsif options[:only]
      only = options[:only]
      only = Array(only).map(&:to_s)
      attributes.slice(*only)

    else
      attributes
    end
  end

  def self.validate_options(options)
    keys = options.keys
    invalid_options = (keys - VALID_OPTIONS)
    raise ArgumentError, "Options does not specify #{invalid_options.inspect}" unless invalid_options.empty?
  end
end
