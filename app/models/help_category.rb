class HelpCategory
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  #############################
  attr_accessible :name,
                  :name_translations,
                  :sort_order

  #############################
  field :name, type: String, localize: true
  field :sort_order, type: Integer, default: 1
  has_many :help_category_mappers

  #############################
  index ({ :name => 1})
  index ({ :sort_order => 1})

  #############################
  slug :name, history: true do |help_category|
    help_category.name_translations[I18n.default_locale.to_s].to_url
  end

  #############################
  # Validations

  validates_presence_of :sort_order

  def validates_presence_of_name_for_default_language
    default_language = I18n.default_locale.to_s

    return if name_translations[default_language].present?

    errors.add(:base,
               I18n.t('errors.messages.translation_default_lang',
                      field_name: self.class.human_attribute_name('name'),
                      language: Language.get_name(default_language),
                      msg: I18n.t('errors.messages.blank')))
  end
  validate :validates_presence_of_name_for_default_language

  #############################
  # Callbacks

  # if name or content are '', reset value to nil so fallback works
  def set_to_nil
    self.name_translations.keys.each do |key|
      self.name_translations[key] = nil if self.name_translations[key].empty?
    end
  end

  before_save :set_to_nil

  #############################
  # Scopes

  def self.sorted
    order_by([[:sort_order, :asc], [:name, :asc]])
  end

  def self.used_in_help_article
    where(:id.in => HelpCategoryMapper.pluck(:help_category_id).uniq)
  end
end
